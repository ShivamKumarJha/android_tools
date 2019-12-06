#!/usr/bin/env python

from __future__ import print_function

import sys
import time
from multiprocessing import Event, Pool, Process, Queue
from subprocess import PIPE, Popen

try:
    from Queue import Empty as Queue_Empty
except ImportError:
    from queue import Empty as Queue_Empty


def run_subprocess(cmd):
    sp = Popen(cmd, stdout=PIPE, stderr=PIPE,
               shell=True, universal_newlines=True)
    comm = sp.communicate()
    exit_code = sp.returncode
    if exit_code != 0:
        print("There was an error running the subprocess.\n"
              "cmd: %s\n"
              "exit code: %d\n"
              "stdout: %s\n"
              "stderr: %s" % (cmd, exit_code, comm[0], comm[1]))
    return comm


def get_tags(tag_name):
    cmd = "git tag -l %s" % tag_name
    comm = run_subprocess(cmd)
    return comm[0].strip("\n").split("\n")


def get_total_changes(tag_name):
    cmd = "git diff %s --shortstat" % tag_name
    comm = run_subprocess(cmd)
    try:
        a, d = comm[0].split(",")[1:]
        a = int(a.strip().split()[0])
        d = int(d.strip().split()[0])
    except ValueError:
        total = None
    else:
        total = a + d
    return total


def worker(tag_name):
    tc = get_total_changes(tag_name)
    worker.q.put((tag_name, tc))


def worker_init(q):
    worker.q = q


def background(q, e, s):
    best = 9999999999999
    tag = ""
    while True:
        try:
            tn, tc = q.get(False)
        except Queue_Empty:
            if e.is_set():
                break
        else:
            if best > tc:
                best = tc
                tag = tn
    print("%s" % tag)


def main():
    import argparse  # Only needed for main()
    parser = argparse.ArgumentParser()
    parser.add_argument("-j", action="store", dest="jobs", default=1, type=int,
                        metavar="N", help="number of jobs to run at once")
    parser.add_argument("-s", action="store_true", dest="silent", default=False,
                        help="reduce the verbosity of the output")
    parser.add_argument("tag_name", metavar="<Tag Name>",
                        help="tag name to search for (can contain wildcards)")
    args = parser.parse_args()

    tags = get_tags(args.tag_name)
    if not tags:
        sys.exit(1)

    queue = Queue()
    event = Event()

    b = Process(target=background, args=(queue, event, args.silent))
    b.start()

    pool = Pool(args.jobs, worker_init, [queue])
    pool.map(worker, tags)

    pool.close()
    pool.join()
    event.set()
    b.join()


if __name__ == '__main__':
    main()
