#!/bin/bash

rsync -avz --exclude-from '.rsync_exclude' ./ we@norns.local://home/we/dust/code/arc_params
