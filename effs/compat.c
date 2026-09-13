// Bendquest's host effects. Game strings and draw lists use List, while
// base IO uses String; the conversion is confined to this boundary.
#include <sys/time.h>
#include <netdb.h>
#include <netinet/tcp.h>

static Term bq_nil(void) { return term_pak(CID_NIL, 0); }
static Term bq_cons(Env e, Term h, Term t) { return io_node(e, CID_CON, h, t, IO_HOTS & 16); }
static Term bq_unit(void) { return term_pak(CID_UNIT, 0); }
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
  while (term_aux(t) == CID_CON) {
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
  return io_box(e, CID_FAIL, io_tup(e, code, bq_string(e, s, strlen(s))), IO_HOTS & 8);
}
static Term bq_bytes(Env e, const char* s, size_t n) {
  return io_node(e, CID_COMPAT_BQ_BYTES_BYTES, n, bq_raw(e, s, n), 1);
}
static char* bq_bytes_c(Env e, Term t, u64* len) {
  Term f[2]; spare_free(e, cls_fit(2), ctr_take(e, t, 2, f));
  u32* ws = bq_words(e, f[1], len); char* p = io_mem(malloc(*len + 1));
  for (u64 i = 0; i < *len; i++) p[i] = (char)ws[i];
  p[*len] = 0; free(ws); return p;
}
static Term bq_chan_send(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(io_hand_c(e, f[0]));
  if (!row || row->shut || (row->size == row->room && !row->wait)) {
    term_drop(e, f[1]); return bq_fail(e, EAGAIN);
  }
  if (row->wait && row->wait->item == TERM_HOLE) chan_wake(row, chan_some(e, f[1]));
  else { row->ring[(row->head + row->size) % row->room] = f[1]; row->size++; }
  return io_done(e, bq_unit());
}
static Term bq_chan_poll(Env e, Term* f, IoWork* w) {
  IoHand h = io_hand_c(e, f[0]); ChanRow* row = chan_at(h);
  if (row && row->size) {
    Term v = chan_take(row);
    if (row->shut && !row->size) chan_free(h, row);
    return io_done(e, v);
  }
  return io_box(e, CID_FAIL, bq_unit(), IO_HOTS & 8);
}
static Term bq_print(Env e, Term* f, IoWork* w) {
  u64 n; char* s = bq_cstr(e, f[0], &n); io_out(stdout, s, n); io_out(stdout, "\n", 1); free(s); return bq_unit();
}
static Term bq_print_err(Env e, Term* f, IoWork* w) {
  u64 n; char* s = bq_cstr(e, f[0], &n); io_out(stderr, s, n); io_out(stderr, "\n", 1); free(s); return bq_unit();
}
static Term bq_now(Env e, Term* f, IoWork* w) { return (u32)time(NULL); }
static Term bq_now_ms(Env e, Term* f, IoWork* w) { return (u32)(io_tick() / 1000000); }
static Term bq_rand(Env e, Term* f, IoWork* w) { return arc4random(); }
static Term bq_args(Env e, Term* f, IoWork* w) {
  const char* p = getenv("BQ_SERVER_PORT");
  return p ? bq_cons(e, bq_string(e, "server", 6), bq_cons(e, bq_string(e, p, strlen(p)), bq_nil())) : bq_nil();
}
static Term bq_get_env(Env e, Term* f, IoWork* w) {
  u64 n; char* s = bq_cstr(e, f[0], &n); const char* v = getenv(s); free(s);
  return v ? io_done(e, bq_string(e, v, strlen(v))) : bq_fail(e, ENOENT);
}
static void bq_read_call(IoWork* w) {
  FILE* f = fopen(w->text, "rb");
  if (!f) { w->fall.code = errno; return; }
  size_t cap = 4096; w->data = io_mem(malloc(cap)); w->size = 0;
  for (;;) {
    size_t n = fread(w->data + w->size, 1, cap - w->size, f); w->size += n;
    if (w->size < cap) break;
    w->data = io_mem(realloc(w->data, cap *= 2));
  }
  if (ferror(f)) w->fall.code = errno ? errno : EIO;
  fclose(f);
}
static Term bq_read_pack(Env e, IoWork* w) {
  Term r = w->fall.code ? bq_fail(e, w->fall.code) : io_done(e, bq_string(e, w->data, w->size));
  free(w->text); free(w->data); return r;
}
static Term bq_read(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); return io_work(w, bq_read_call, bq_read_pack);
}
static void bq_write_call(IoWork* w) {
  // Replace atomically: an interrupted save must not truncate the database.
  size_t n = strlen(w->text); char* tmp = io_mem(malloc(n + 16));
  snprintf(tmp, n + 16, "%s.tmpXXXXXX", w->text); int fd = mkstemp(tmp);
  if (fd < 0) w->fall.code = errno;
  else {
    u64 at = 0;
    while (at < w->size) { ssize_t n = write(fd, w->data + at, w->size - at); if (n <= 0) { w->fall.code = errno ? errno : EIO; break; } at += n; }
    if (!w->fall.code && fsync(fd)) w->fall.code = errno;
    if (close(fd) && !w->fall.code) w->fall.code = errno;
    if (!w->fall.code && rename(tmp, w->text)) w->fall.code = errno;
    if (w->fall.code) unlink(tmp);
  }
  free(tmp);
}
static Term bq_unit_pack(Env e, IoWork* w) {
  Term r = w->fall.code ? bq_fail(e, w->fall.code) : io_done(e, bq_unit());
  free(w->text); free(w->data); return r;
}
static Term bq_write(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); w->data = bq_cstr(e, f[1], &w->size);
  return io_work(w, bq_write_call, bq_unit_pack);
}
static void bq_exec_call(IoWork* w) {
  FILE* f = popen(w->text, "r");
  if (!f) { w->fall.code = errno; return; }
  size_t cap = 4096; w->data = io_mem(malloc(cap)); w->size = 0;
  for (;;) { size_t n = fread(w->data + w->size, 1, cap - w->size, f); w->size += n; if (w->size < cap) break; w->data = io_mem(realloc(w->data, cap *= 2)); }
  if (pclose(f)) w->fall.code = EIO;
}
static Term bq_exec_pack(Env e, IoWork* w) {
  Term r = w->fall.code ? bq_fail(e, w->fall.code) : io_done(e, bq_bytes(e, w->data, w->size));
  free(w->text); free(w->data); return r;
}
static Term bq_exec(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); return io_work(w, bq_exec_call, bq_exec_pack);
}

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
static u32 bq_token_p(Env e, Term t) { return term_tag(t) == TAG_PAK ? (u32)term_loc(t) : (u32)e.mem[term_peek(e, t)]; }
static Term bq_socket_done(Env e, int fd) {
  u32 t = bq_socket(fd); return t ? io_done(e, term_pak(CID_COMPAT_BQ_TCP_TCP, t)) : bq_fail(e, EMFILE);
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
static Term bq_park_read(u32 fid, Term* f, u32 n, int fd) {
  IoJob* j = io_mem(calloc(1, sizeof(IoJob) + (n + 1) * sizeof(Term)));
  j->what = io_eff_at(true, fid); j->word = fd; j->cont = f[n];
  memcpy(j->args, f, (n + 1) * sizeof(Term)); *io_park_at = j; io_park_at = &j->next; return IO_PARK;
}
static Term bq_accept(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0]));
  int s = fd < 0 ? -1 : accept(fd, NULL, NULL);
  if (s < 0 && fd >= 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) return bq_park_read(FID_BQ_TCP_ACCEPT, f, 1, fd);
  term_drop(e, f[0]);
  if (s < 0) return bq_fail(e, fd < 0 ? EBADF : errno);
  bq_socket_options(s); return bq_socket_done(e, s);
}
static void bq_connect_call(IoWork* w) {
  struct addrinfo hint = {.ai_family = AF_INET, .ai_socktype = SOCK_STREAM}, *ai = NULL;
  char port[16]; snprintf(port, sizeof port, "%u", w->word);
  if (getaddrinfo(w->text, port, &hint, &ai)) { w->fall.code = EHOSTUNREACH; return; }
  int fd = socket(ai->ai_family, ai->ai_socktype, 0);
  if (fd < 0) { w->fall.code = errno; freeaddrinfo(ai); return; }
  fcntl(fd, F_SETFL, O_NONBLOCK); int r = connect(fd, ai->ai_addr, ai->ai_addrlen); freeaddrinfo(ai);
  if (r < 0 && errno == EINPROGRESS) {
    struct pollfd p = {.fd = fd, .events = POLLOUT}; r = poll(&p, 1, 3000);
    int er = 0; socklen_t n = sizeof er;
    if (r <= 0) w->fall.code = r == 0 ? ETIMEDOUT : errno;
    else if (getsockopt(fd, SOL_SOCKET, SO_ERROR, &er, &n) || er) w->fall.code = er ? er : errno;
  } else if (r < 0) w->fall.code = errno;
  if (w->fall.code) close(fd);
  else { fcntl(fd, F_SETFL, 0); bq_socket_options(fd); w->word = fd; }
}
static Term bq_connect_pack(Env e, IoWork* w) {
  free(w->text); return w->fall.code ? bq_fail(e, w->fall.code) : bq_socket_done(e, w->word);
}
static Term bq_connect(Env e, Term* f, IoWork* w) {
  u64 n; w->text = bq_cstr(e, f[0], &n); w->word = f[1]; return io_work(w, bq_connect_call, bq_connect_pack);
}
static void bq_send_call(IoWork* w) {
  u64 at = 0;
  while (at < w->size) { ssize_t n = send((int)w->word, w->data + at, w->size - at, 0); if (n <= 0) { w->fall.code = errno ? errno : EPIPE; break; } at += n; }
  close((int)w->word);
}
static Term bq_send(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0])); term_drop(e, f[0]); w->data = bq_bytes_c(e, f[1], &w->size);
  int d = fd < 0 ? -1 : dup(fd);
  if (d < 0) { free(w->data); return bq_fail(e, EBADF); }
  w->word = d; return io_work(w, bq_send_call, bq_unit_pack);
}
static Term bq_recv(Env e, Term* f, IoWork* w) {
  int fd = bq_fd(bq_token_p(e, f[0])); size_t cap = (u32)f[1]; if (cap > 1048576) cap = 1048576;
  char* p = io_mem(malloc(cap + 1)); ssize_t n = fd < 0 ? -1 : recv(fd, p, cap, MSG_DONTWAIT);
  if (n < 0 && fd >= 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) { free(p); return bq_park_read(FID_BQ_TCP_RECV, f, 2, fd); }
  term_drop(e, f[0]); Term r = n < 0 ? bq_fail(e, fd < 0 ? EBADF : errno) : io_done(e, bq_bytes(e, p, n)); free(p); return r;
}
static Term bq_close(Env e, Term* f, IoWork* w) {
  u32 t = bq_token_p(e, f[0]); int fd = bq_fd(t); term_drop(e, f[0]);
  if (fd >= 0) { bq_sockets[t & 4095].token = 0; shutdown(fd, SHUT_RDWR); close(fd); }
  return bq_unit();
}
static Term bq_finish(Env e, Term* f, IoWork* w) {
  io_sync();
  exit(0);
}
static void __attribute__((constructor)) bq_effects(void) {
#define BQ_EFFECT(n, f) io_eff(FID_BQ_##n, CID_BQ_##n, f, 0)
  BQ_EFFECT(IO_FINISH, bq_finish);
  BQ_EFFECT(CHAN_SEND, bq_chan_send); BQ_EFFECT(CHAN_POLL, bq_chan_poll);
  BQ_EFFECT(IO_PRINT, bq_print); BQ_EFFECT(IO_PRINT_ERR, bq_print_err);
  BQ_EFFECT(IO_NOW, bq_now); BQ_EFFECT(IO_NOW_MS, bq_now_ms);
  BQ_EFFECT(IO_RAND_WORD, bq_rand); BQ_EFFECT(IO_ARGS, bq_args);
  BQ_EFFECT(IO_GET_ENV, bq_get_env); BQ_EFFECT(IO_READ_TEXT, bq_read);
  BQ_EFFECT(IO_WRITE_TEXT, bq_write); BQ_EFFECT(IO_EXEC, bq_exec);
  BQ_EFFECT(TCP_LISTEN, bq_listen); BQ_EFFECT(TCP_ACCEPT, bq_accept);
  BQ_EFFECT(TCP_CONNECT, bq_connect); BQ_EFFECT(TCP_SEND, bq_send);
  BQ_EFFECT(TCP_RECV, bq_recv); BQ_EFFECT(TCP_CLOSE, bq_close);
#undef BQ_EFFECT
}
