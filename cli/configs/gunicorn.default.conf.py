import multiprocessing

bind = 'unix:/tmp/sockets/hawthorne.sock'
workers = multiprocessing.cpu_count() * 2 + 1
