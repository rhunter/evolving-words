#= require 'jquery-1.7.2'
#= require 'jquery.mustache'
#= require 'wordDistance'

class Game
  constructor: (startingWord) ->
    @advanceToWord(startingWord)

  advanceToWord: (newWord) ->
    @currentWord = newWord
    @candidateNextWords = all_words
      .filter(isCloseTo(@currentWord))
      .filter (word) =>
        word != @currentWord
    @trigger('word.change')

  stages_of_evolution: [
    'cell'
    'amoeba'
    'worm'
    'fish' # eye heart
    'frog' # leg
    'reptile' # hair milk
    'mammal' # upright
    'human'
  ]

  helpful_words: [
    'rate'
    'sing'
    'den'
    'man'
    'over'
    'tie'
    'kin'
    'imp'
    'ear'
    'art'
    'ill'
    'age'
    'she'
    'act'
    'the'
    'one'
    'ass'
    'sin'
    'end'
    'and'
    'for'
    'cat'
    'era'
    'ally'
    'ran'
    'ten'
    'her'
    'able'
    'ring'
    'ant'
    'ions'
    'red'
    'men'
    'rat'
    'all'
    'tin'
    'ate'
  ]
# all_words = [
#   'head'
#   'hear'
#   'heart'
#   'hearth'
#   'hearty'
#   'heard'
#   'beard'
# ]

  currentWord: 'heart'
  candidateNextWords: []
#   'hear'
#   'heard'
#   'hearth'
#   'hearty'
# ]

  events: {}

  on: (eventName, callback) ->
    @events[eventName] ||= []
    @events[eventName].push callback

  trigger: (eventName) ->
    for callback in (@events[eventName] || [])
      callback()

(($) ->
  game = null

  paintCurrentWord = ->
    $('.current-word').text(game.currentWord)

  paintCandidateNextWords = (words) ->
    listItemHtml = (text) ->
      template = """
      <li class="{{class}}">
        <a href="{{href}}">{{word}}</a>
      </li>
      """
      $.mustache template,
        class: ['add', 'remove', 'change'][(Math.floor(Math.random()*3))]
        word: text
        href: '#' + text
    replacementHtml = words.map(listItemHtml).join("\n")
    $('.canvas > ul').html(replacementHtml)

  onWordChange = ->
    paintCurrentWord()
    paintCandidateNextWords(game.candidateNextWords)

  onHashChange = ->
    newWord = window.location.hash.replace(/^#*/, '')
    game.advanceToWord(newWord)
    

  $ ->
    game = new Game('heart')
    game.on 'word.change', onWordChange
    $(window).on('hashchange', onHashChange)
    onHashChange()
    
# on paint
  # paint main with current_word
    paintCandidateNextWords(game.candidateNextWords)

# on choose next_word
#   evolve if next_word == target_word
#   health--
#   current_word = selected_word
#   award_bonuses for current_word
#   paint

)(jQuery)

# for word in candidate_next_words
#   maybe = areWordsAdjacent(current_word, word)
#   console.log("Is #{word} close? #{maybe}")
