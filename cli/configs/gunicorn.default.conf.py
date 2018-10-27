import multiprocessing

bind = 'unix:/var/run/hawthorne.sock'
workers = multiprocessing.cpu_count() * 2 + 1
