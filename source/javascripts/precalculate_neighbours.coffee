#!/usr/bin/env coffee
fs = require 'fs'
{uptime} = require 'os'
{debug} = require 'util'
{isCloseTo} = require './wordDistance'
{all_words} = require './dictionary'

neighbours = {}

sample_words = all_words
debug(before = uptime())
neighbours[word] = all_words.filter(isCloseTo(word)) for word in sample_words
debug(after = uptime())
debug("done in #{after-before} seconds")

fs.writeFileSync('wordneighbours.json', JSON.stringify(neighbours))