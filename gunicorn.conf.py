import multiprocessing

bind = "unix:/tmp/boompanel.sock"
workers = multiprocessing.cpu_count() * 2 + 1
