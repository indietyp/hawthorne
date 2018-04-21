import multiprocessing

bind = 'unix:/tmp/sockets/landing.sock'
workers = multiprocessing.cpu_count() * 2 + 1
