import multiprocessing

bind = "unix:/tmp/bellwether.sock"
workers = multiprocessing.cpu_count() * 2 + 1
