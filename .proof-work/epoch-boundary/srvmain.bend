import ../../bend3/bend-base/Base
import ../../bend3/bend-base/IO/Chan
import ./proto
import ./server

def log_printer(fuel: U32, lg: Chan(String)) -> IO(Unit):
  match fuel:
    case 0:
      IO.pure(Unit, Unit.U{})
    case 1+f:
      do IO(Unit):
        r <- Chan.recv(String, lg)
        match r:
          case Result.Done{line}:
            do IO(Unit):
              IO.print("[bendquest] " ++ line)
              log_printer(f, lg)
          case Result.Fail{e}:
            return Unit.U{}

def stat_drain(fuel: U32, stat: Chan(String)) -> IO(Unit):
  match fuel:
    case 0:
      IO.pure(Unit, Unit.U{})
    case 1+f:
      do IO(Unit):
        r <- Chan.recv(String, stat)
        match r:
          case Result.Done{line}:
            stat_drain(f, stat)
          case Result.Fail{e}:
            return Unit.U{}

def main() -> IO(Unit):
  do IO(Unit):
    lg <- Chan.new(String, 256)
    ctl <- Chan.new(U32, 8)
    stat <- Chan.new(String, 64)
    IO.spawn(log_printer(U32.MAX, lg))
    IO.spawn(stat_drain(U32.MAX, stat))
    server_start(4977, lg, ctl, stat)
