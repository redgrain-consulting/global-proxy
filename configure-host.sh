#!/usr/bin/env bash

#  Run this on the host to configure the site to be served on coffee1-website.dev.redgrain.co.uk
sudo bash -c 'echo "127.0.0.1 coffee1-website.dev.redgrain.co.uk" >> /etc/hosts' && echo "✓ Added coffee1-website.dev.redgrain.co.uk to /etc/hosts"