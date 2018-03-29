import multiprocessing

bind = 'unix:/tmp/hawthorne.sock'
workers = multiprocessing.cpu_count() * 2 + 1
