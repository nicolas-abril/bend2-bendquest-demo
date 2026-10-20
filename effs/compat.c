// Bendquest's host effects: the wall clock, an atomic file replace and the
// shared TCP sockets, which Base does not provide (Base's Socket is affine,
// while the game's reader and writer share one connection). Game strings and
// draw lists use List, and the helpers here also serve effs/raylib.c.
#include <sys/time.h>
#include <netdb.h>
#include <netinet/tcp.h>

static Term bq_nil(void) { return term_pak(CID(Nil), 0); }
static Term bq_cons(Env e, Term h, Term t) { return io_node(e, CID(Con), h, t); }
static Term bq_unit(void) { return term_pak(CID(Unit), 0); }
static Term bq_raw(Env e, const char* s, size_t n) {
  Term t = bq_nil();
  while (n) t = bq_cons(e, (unsigned char)s[--n], t);
  return t;
}
static Term bq_string(Env e, const char* s, size_t n) {
  u32* codes = io_mem(malloc((n + 1) * sizeof(u32))); size_t count = 0;
  for (size_t i = 0; i < n;) {
    u32 c = (unsigned char)s[i++], more = 0, min = 0;
    if (c >= 0xc2 && c <= 0xdf) { c &= 31; more = 1; min = 128; }
    else if (c >= 0xe0 && c <= 0xef) { c &= 15; more = 2; min = 2048; }
    else if (c >= 0xf0 && c <= 0xf4) { c &= 7; more = 3; min = 65536; }
    else if (c >= 128) c = 65533;
    for (u32 j = 0; j < more; j++) {
      if (i >= n || ((unsigned char)s[i] & 0xc0) != 0x80) { c = 65533; break; }
      c = (c << 6) | ((unsigned char)s[i++] & 63);
    }
    if (c < min || c > 0x10ffff || (c >= 0xd800 && c <= 0xdfff)) c = 65533;
    codes[count++] = c;
  }
  Term t = bq_nil(); while (count) t = bq_cons(e, codes[--count], t);
  free(codes); return t;
}
static u32* bq_words(Env e, Term t, u64* len) {
  size_t n = 0, cap = 256;
  u32* p = io_mem(malloc(cap * sizeof(u32)));
  while (term_aux(t) == CID(Con)) {
    Term f[2];
    spare_free(e, cls_fit(2), ctr_take(e, t, 2, f));
    if (n == cap) p = io_mem(realloc(p, (cap *= 2) * sizeof(u32)));
    p[n++] = (u32)f[0]; t = f[1];
  }
  *len = n; return p;
}
static char* bq_cstr(Env e, Term t, u64* len) {
  u64 n; u32* p = bq_words(e, t, &n);
  char* s = io_mem(malloc(n * 4 + 1)); size_t j = 0;
  for (u64 i = 0; i < n; i++) {
    u32 c = p[i];
    if (c < 128) s[j++] = c;
    else if (c < 2048) { s[j++] = 0xc0 | c >> 6; s[j++] = 0x80 | (c & 63); }
    else if (c < 65536) { s[j++] = 0xe0 | c >> 12; s[j++] = 0x80 | (c >> 6 & 63); s[j++] = 0x80 | (c & 63); }
    else { s[j++] = 0xf0 | c >> 18; s[j++] = 0x80 | (c >> 12 & 63); s[j++] = 0x80 | (c >> 6 & 63); s[j++] = 0x80 | (c & 63); }
  }
  s[j] = 0; free(p); *len = j; return s;
}
static Term bq_fail(Env e, int code) {
  const char* s = strerror(code);
  return io_box(e, CID(Fail), io_tup(e, code, bq_string(e, s, strlen(s))));
}
// A twin file serves every effect it declares, but the compiler defines a
// constructor's id only when the program reaches it, so each part that names
// one builds only then, and an effect registers only when its id exists.
#ifdef CID(Bq.Bytes.Bytes)
static Term bq_bytes(Env e, const char* s, size_t n) {
  return io_node(e, CID(Bq.Bytes.Bytes), n, bq_raw(e, s, n));
}
static char* bq_bytes_c(Env e, Term t, u64* len) {
  Term f[2]; spare_free(e, cls_fit(2), ctr_take(e, t, 2, f));
  u32* ws = bq_words(e, f[1], len); char* p = io_mem(malloc(*len + 1));
  for (u64 i = 0; i < *len; i++) p[i] = (char)ws[i];
  p[*len] = 0; free(ws); return p;
}
#endif
static Term bq_now(Env e, Term* f, IoWork* w) { return (u32)time(NULL); }
static void bq_write_call(IoWork* w) {
  w->code = 0;
  // Replace atomically: an interrupted save must not truncate the database.
  size_t n = strlen(w->text); char* tmp = io_mem(malloc(n + 16));
  snprintf(tmp, n + 16, "%s.tmpXXXXXX", w->text); int fd = mkstemp(tmp);
  if (fd < 0) w->code = errno;
  else {
    u64 at = 0;
    while (at < w->size) { ssize_t n = write(fd, w->data + at, w->size - at); if (n <= 0) { w->code = errno ? errno : EIO; break; } at += n; }
    if (!w->code && fsync(fd)) w->code = errno;
    if (close(fd) && !w->code) w->code = errno;
    if (!w->code && rename(tmp, w->text)) w->code = errno;
    if (w->code) unlink(tmp);
  }
  free(tmp);
}
static Term bq_unit_pack(Env e, IoWork* w) {
  Term r = w->code ? bq_fail(e, w->code) : io_done(e, bq_unit());
  free(w->text); free(w->data); return r;
}
static Term bq_write(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); w->data = bq_cstr(e, f[1], &w->size);
  return io_work(w, bq_write_call, bq_unit_pack);
}

#ifdef CID(Bq.TCP.TCP)
// Socket tokens retain a generation, so a late writer cannot close a new
// connection that happened to reuse the same OS descriptor.
static struct { int fd; u32 token; } bq_sockets[4096];
static u32 bq_token;
static int bq_fd(u32 t) { return bq_sockets[t & 4095].token == t ? bq_sockets[t & 4095].fd : -1; }
static u32 bq_socket(int fd) {
  for (u32 i = 0; i < 4096; i++) { u32 t = ++bq_token; if (!t) t = ++bq_token;
    if (!bq_sockets[t & 4095].token) { bq_sockets[t & 4095].token = t; bq_sockets[t & 4095].fd = fd; return t; }
  }
  close(fd); return 0;
}
static u32 bq_token_p(Env e, Term t) { return term_tag(t) == TAG_PAK ? (u32)term_loc(t) : (u32)e.mem[term_peek(e.mem, t)]; }
static Term bq_socket_done(Env e, int fd) {
  u32 t = bq_socket(fd); return t ? io_done(e, term_pak(CID(Bq.TCP.TCP), t)) : bq_fail(e, EMFILE);
}
static void bq_socket_options(int fd) {
  struct timeval timeout = {0, 300000}; setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof timeout);
  int one = 1; setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
}
static Term bq_listen(Env e, Term* f, IoWork* w) {
  int fd = socket(AF_INET, SOCK_STREAM, 0); if (fd < 0) return bq_fail(e, errno);
  int one = 1; setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
  struct sockaddr_in a = {.sin_family = AF_INET, .sin_port = htons((u32)f[0]), .sin_addr = {.s_addr = INADDR_ANY}};
  if (bind(fd, (void*)&a, sizeof a) || listen(fd, 64) || fcntl(fd, F_SETFL, O_NONBLOCK)) { int er = errno; close(fd); return bq_fail(e, er); }
  return bq_socket_done(e, fd);
}
// An accept or a receive that finds nothing parks its activation until the
// descriptor is readable and resumes here (the listener and every socket
// are non-blocking).
static Term bq_accept_more(Env e, IoWork* w) {
  int fd = (int)w->hand;
  int s = accept(fd, NULL, NULL);
  if (s < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return io_wait_on(w, fd, POLLIN, 0, bq_accept_more);
  if (s < 0) return bq_fail(e, errno);
  bq_socket_options(s); return bq_socket_done(e, s);
}
static Term bq_accept(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0])); term_drop(e, f[0]);
  if (fd < 0) return bq_fail(e, EBADF);
  w->hand = fd; return bq_accept_more(e, w);
}
static void bq_connect_call(IoWork* w) {
  w->code = 0;
  struct addrinfo hint = {.ai_family = AF_INET, .ai_socktype = SOCK_STREAM}, *ai = NULL;
  char port[16]; snprintf(port, sizeof port, "%u", w->word);
  if (getaddrinfo(w->text, port, &hint, &ai)) { w->code = EHOSTUNREACH; return; }
  int fd = socket(ai->ai_family, ai->ai_socktype, 0);
  if (fd < 0) { w->code = errno; freeaddrinfo(ai); return; }
  fcntl(fd, F_SETFL, O_NONBLOCK); int r = connect(fd, ai->ai_addr, ai->ai_addrlen); freeaddrinfo(ai);
  if (r < 0 && errno == EINPROGRESS) {
    struct pollfd p = {.fd = fd, .events = POLLOUT}; r = poll(&p, 1, 3000);
    int er = 0; socklen_t n = sizeof er;
    if (r <= 0) w->code = r == 0 ? ETIMEDOUT : errno;
    else if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &er, &n) || er) w->code = er ? er : errno;
  } else if (r < 0) w->code = errno;
  if (w->code) close(fd);
  else { fcntl(fd, F_SETFL, 0); bq_socket_options(fd); w->word = fd; }
}
static Term bq_connect_pack(Env e, IoWork* w) {
  free(w->text); return w->code ? bq_fail(e, w->code) : bq_socket_done(e, w->word);
}
static Term bq_connect(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); w->word = f[1]; return io_work(w, bq_connect_call, bq_connect_pack);
}
#ifdef CID(Bq.Bytes.Bytes)
static void bq_send_call(IoWork* w) {
  w->code = 0;
  u64 at = 0;
  while (at < w->size) { ssize_t n = send((int)w->word, w->data + at, w->size - at, 0); if (n <= 0) { w->code = errno ? errno : EPIPE; break; } at += n; }
  close((int)w->word);
}
static Term bq_send(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0])); term_drop(e, f[0]); w->data = bq_bytes_c(e, f[1], &w->size);
  w->text = NULL; // bq_unit_pack frees it; the runtime does not clear w
  int d = fd < 0 ? -1 : dup(fd);
  if (d < 0) { free(w->data); return bq_fail(e, EBADF); }
  w->word = d; return io_work(w, bq_send_call, bq_unit_pack);
}
static Term bq_recv_more(Env e, IoWork* w) {
  int fd = (int)w->hand;
  ssize_t n = recv(fd, w->data, (size_t)w->made, MSG_DONTWAIT);
  if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return io_wait_on(w, fd, POLLIN, 0, bq_recv_more);
  Term r = n < 0 ? bq_fail(e, errno) : io_done(e, bq_bytes(e, w->data, n));
  free(w->data); return r;
}
static Term bq_recv(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0])); term_drop(e, f[0]);
  if (fd < 0) return bq_fail(e, EBADF);
  size_t cap = (u32)f[1]; if (cap > 1048576) cap = 1048576;
  w->hand = fd; w->made = (intptr_t)cap; w->data = io_mem(malloc(cap + 1));
  return bq_recv_more(e, w);
}
#endif
static Term bq_close(Env e, Term* f, IoWork* w) {
  u32 t = bq_token_p(e, f[0]); int fd = bq_fd(t); term_drop(e, f[0]);
  if (fd >= 0) { bq_sockets[t & 4095].token = 0; shutdown(fd, SHUT_RDWR); close(fd); }
  return bq_unit();
}
#endif
static void __attribute__((constructor)) bq_effects(void) {
#ifdef CID(Bq.IO.now)
  io_eff(CID(Bq.IO.now), bq_now);
#endif
#ifdef CID(Bq.IO.write_text)
  io_eff(CID(Bq.IO.write_text), bq_write);
#endif
#ifdef CID(Bq.TCP.TCP)
#ifdef CID(Bq.TCP.listen)
  io_eff(CID(Bq.TCP.listen), bq_listen);
#endif
#ifdef CID(Bq.TCP.accept)
  io_eff(CID(Bq.TCP.accept), bq_accept);
#endif
#ifdef CID(Bq.TCP.connect)
  io_eff(CID(Bq.TCP.connect), bq_connect);
#endif
#if defined(CID(Bq.TCP.send)) && defined(CID(Bq.Bytes.Bytes))
  io_eff(CID(Bq.TCP.send), bq_send);
#endif
#if defined(CID(Bq.TCP.recv)) && defined(CID(Bq.Bytes.Bytes))
  io_eff(CID(Bq.TCP.recv), bq_recv);
#endif
#ifdef CID(Bq.TCP.close)
  io_eff(CID(Bq.TCP.close), bq_close);
#endif
#endif
}
