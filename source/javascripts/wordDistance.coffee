
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

# a generator for word pairs
# eg: all_words.map(isCloseTo('something'))
window.isCloseTo = (referenceWord) ->
  (candidateWord) -> areWordsAdjacent(referenceWord, candidateWord)


window.areWordsAdjacent = areWordsAdjacent