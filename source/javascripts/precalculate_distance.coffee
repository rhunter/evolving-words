neighbours = require './wordneighbours.json'

COST_OF_BAD_WORDS = 30
# there are some words with which I'd rather avoid suprising the player.
# obviously incomplete, but at least one of these came to my attention
# while testing the pathfinding
badWords = [
  'fag'
  'fuck'
  'fucking'
  'fucked'
  'fucker'
  'shit'
  'cunt'
  'piss'
  'nigger'
  'whore'
]
reconstructPath = (cameFrom, currentNode) ->
  if currentNode of cameFrom
    pathSoFar = reconstructPath(cameFrom, cameFrom[currentNode])
    return pathSoFar.concat [currentNode]
  return [currentNode]

routeByAStar = (start, goal) ->
  alreadyCheckedWords = []
  possibilitiesToCheck = [start]
  cameFrom = {}
  costAlongBestKnownPathFrom = {}
  estimatedTotalCostToGoalVia = {}

  possibilityWithCheapestEstimatedCost = ->
    cheapest = possibilitiesToCheck.reduce (cheapestSoFar, possibility) ->
      costViaCheapestSoFar = estimatedTotalCostToGoalVia[cheapestSoFar]
      costViaPossibility = estimatedTotalCostToGoalVia[possibility]
      if costViaPossibility < costViaCheapestSoFar
        return possibility
      else
        return cheapestSoFar
    cheapest
  considerPossibility = (possibilityToCheck) ->
    if possibilityToCheck not in possibilitiesToCheck
      possibilitiesToCheck.push possibilityToCheck
  discardPossibility = (possibilityNotToCheck) ->
    possibilitiesToCheck = (possibility for possibility in possibilitiesToCheck when possibility isnt possibilityNotToCheck)
  estimatedDistanceBetween = (a, b) -> Math.abs(a.length - b.length)
  actualDistanceBetween = (a, b) ->
    # bad words are considered "high cost"
    if (a in badWords) or (b in badWords)
      return COST_OF_BAD_WORDS
    1
  console.log "here we go"

  costAlongBestKnownPathFrom[start] = 0
  estimatedTotalCostToGoalVia[start] = costAlongBestKnownPathFrom[start] + estimatedDistanceBetween(start, goal)

  console.log "starting"
  console.log possibilitiesToCheck
  console.log possibilitiesToCheck.length
  while (possibilitiesToCheck.length) > 0
    console.log "===== STILL LOOKING:"
    console.log "Considering #{possibilitiesToCheck.length} possibilities."
    console.log "Already checked #{alreadyCheckedWords.length} possibilities."
    console.log "------"
    # console.log "what's the cheapest?"
    current = possibilityWithCheapestEstimatedCost()
    console.log "apparently the cheapest is #{current}, which costs #{estimatedTotalCostToGoalVia[current]}"
    if current == goal
      return reconstructPath(cameFrom, goal)
    discardPossibility current
    alreadyCheckedWords.push current
    # console.log "Checking out #{current}'s neighbours..."
    # console.log neighbours[current]
    for neighbour in (neighbours[current] || [])
      # console.log "Checking neighbour: #{neighbour}"
      continue if neighbour in alreadyCheckedWords
      tentativeCostFromStart = costAlongBestKnownPathFrom[current] + actualDistanceBetween(current, neighbour)

      mightBeCloserThanNeighbour = (neighbour not in alreadyCheckedWords) or (tentativeCostFromStart < costAlongBestKnownPathFrom[neighbour])
      # console.log "#{current} might cost #{tentativeCostFromStart} from start, #{mightBeCloserThanNeighbour} closer than #{neighbour} (best #{costAlongBestKnownPathFrom[neighbour]})"
      if mightBeCloserThanNeighbour
        # console.log "Yeah, worth checking #{neighbour}"
        considerPossibility(neighbour)
        cameFrom[neighbour] = current
        costAlongBestKnownPathFrom[neighbour] = tentativeCostFromStart
        estimatedTotalCostToGoalVia[neighbour] = costAlongBestKnownPathFrom[neighbour] + estimatedDistanceBetween(neighbour, goal)
      # console.log "Next!"
  throw new Error("Can't route between #{start} and #{goal} (even after searching #{alreadyCheckedWords.length} words)")


{print} = require 'util'
console.log = ->

stages_of_evolution = process.argv.slice(2)
incrementalPath = (pathSoFar, nextTarget) ->
  lastMilestone = pathSoFar[pathSoFar.length - 1]
  pathToNextTarget = routeByAStar(lastMilestone, nextTarget)
  pathSoFar.concat(pathToNextTarget)
  
print JSON.stringify stages_of_evolution.reduce(incrementalPath, [stages_of_evolution[0]])
# print JSON.stringify(routeByAStar('cell', 'worm'))
