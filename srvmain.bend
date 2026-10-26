# Headless server on port 4977: prints the server's log lines and drains
# its status channel. The same as `./run.sh server 4977`, without the
# client binary's mode switch.
import Base
import ./bendquest.bend as Game
import ./compat.bend as C

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- Game.Bq.headless(4977)
    C.Bq.IO.finish()
