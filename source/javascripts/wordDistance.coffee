areWordsAdjacent = (sourceWord, targetWord) ->
  differenceInLengths = targetWord.length - sourceWord.length
  if differenceInLengths == 1
    return canBeMadeByAddingALetter(sourceWord, targetWord)
  if differenceInLengths == -1
    return canBeMadeByRemovingALetter(sourceWord, targetWord)
  if differenceInLengths == 0
    return canBeMadeByChangingALetter(sourceWord, targetWord)
  false


canBeMadeByAddingALetter = (sourceWord, targetWord) ->
  canBeMadeByRemovingALetter(targetWord, sourceWord)

canBeMadeByChangingALetter = (sourceWord, targetWord) ->
  for potentiallyChangedLetter, i in sourceWord
    wordWithLetterChanged = sourceWord[...i] + targetWord[i] + sourceWord[(i + 1)..]
    return true if wordWithLetterChanged == targetWord
  false

canBeMadeByRemovingALetter = (sourceWord, targetWord) ->
  for potentiallyRemovedLetter, i in sourceWord
    wordWithLetterRemoved = sourceWord[...i] + sourceWord[(i+ 1)..]
    return true if wordWithLetterRemoved == targetWord
  false


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


checkedWordCache = {}
routeByAStar = (start, goal, neighbours) ->
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
    return 1 if b.length < a.length
    return 2 if b.length == a.length
    return 4
  # console.log "here we go"

  costAlongBestKnownPathFrom[start] = 0
  estimatedTotalCostToGoalVia[start] = costAlongBestKnownPathFrom[start] + estimatedDistanceBetween(start, goal)

  # console.log "starting"
  # console.log possibilitiesToCheck
  # console.log possibilitiesToCheck.length
  while (possibilitiesToCheck.length) > 0
    # console.log "===== STILL LOOKING:"
    # console.log "Considering #{possibilitiesToCheck.length} possibilities."
    # console.log "Already checked #{alreadyCheckedWords.length} possibilities."
    # console.log "------"
    # # console.log "what's the cheapest?"
    current = possibilityWithCheapestEstimatedCost()
    # console.log "apparently the cheapest is #{current}, which costs #{estimatedTotalCostToGoalVia[current]}"
    if current == goal
      return reconstructPath(cameFrom, goal)
    discardPossibility current
    alreadyCheckedWords.push current
    # # console.log "Checking out #{current}'s neighbours..."
    # # console.log neighbours[current]
    for neighbour in (neighbours[current] || [])
      # # console.log "Checking neighbour: #{neighbour}"
      continue if neighbour in alreadyCheckedWords
      tentativeCostFromStart = costAlongBestKnownPathFrom[current] + actualDistanceBetween(current, neighbour)

      mightBeCloserThanNeighbour = (neighbour not in alreadyCheckedWords) or (tentativeCostFromStart < costAlongBestKnownPathFrom[neighbour])
      # # console.log "#{current} might cost #{tentativeCostFromStart} from start, #{mightBeCloserThanNeighbour} closer than #{neighbour} (best #{costAlongBestKnownPathFrom[neighbour]})"
      if mightBeCloserThanNeighbour
        # # console.log "Yeah, worth checking #{neighbour}"
        considerPossibility(neighbour)
        cameFrom[neighbour] = current
        costAlongBestKnownPathFrom[neighbour] = tentativeCostFromStart
        estimatedTotalCostToGoalVia[neighbour] = costAlongBestKnownPathFrom[neighbour] + estimatedDistanceBetween(neighbour, goal)
      # # console.log "Next!"
  throw new Error("Can't route between #{start} and #{goal} (even after searching #{alreadyCheckedWords.length} words)")




# a generator for word pairs
# eg: all_words.map(isCloseTo('something'))
this.isCloseTo = (referenceWord) ->
  (candidateWord) -> areWordsAdjacent(referenceWord, candidateWord)

this.suggestRouteBetween = (word1, word2, neighbours, callback) ->
  route = routeByAStar(word1, word2, neighbours)
  callback(route)

this.areWordsAdjacent = areWordsAdjacent

this.onmessage = (e) ->
  data = JSON.parse(e.data)
  if data.command == 'suggestRouteBetween'
    route = routeByAStar(data.source, data.target, data.neighbours)
    postMessage JSON.stringify
        result: 'suggestedRoute'
        source: data.source
        target: data.target
        route: route
