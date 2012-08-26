#= require 'jquery-1.7.2'
#= require 'jquery.mustache'
#= require 'd3.v2'
#= require 'wordDistance'
#= require 'dictionary'

class Game
  constructor: (@wordNeighbours) ->
    startingWord = @stagesOfEvolution[0].name
    @nextEvolutionStageIndex = 0
    @evolve()
    console.log "starting with #{startingWord}"
    @advanceToWord(startingWord)

  advanceToWord: (newWord) ->
    throw new Error("there is supposed to be a word") unless newWord
    @currentWord = newWord
    @candidateNextWords = (@wordNeighbours[@currentWord] || [])
      .filter (word) -> word != newWord
    @evolve() if @currentWord == @nextStage.name
    setTimeout(@suggestWaypoint, 0)
    @trigger('word.change')

  evolve: ->
    stage = @stagesOfEvolution[@nextEvolutionStageIndex]
    @currentBoosters = stage.bonuses
    @nextEvolutionStageIndex++
    if @stagesOfEvolution.length <= @nextEvolutionStageIndex
      @trigger('win')
      return

    @nextStage = @stagesOfEvolution[@nextEvolutionStageIndex]
    @trigger('evolve', stage)

  suggestWaypoint: =>
    worker = new Worker('javascripts/wordDistance.js')
    worker.onmessage = (e) =>
      {route} = JSON.parse(e.data)
      console.log(route)
      if route.length < 3
        @trigger('hint.unnecessary')
        return
      helpfulIndex = Math.floor(route.length / 3)
      @trigger('hint.waypoint_suggested', route[helpfulIndex])

    worker.postMessage(JSON.stringify
        command: 'suggestRouteBetween'
        source: @currentWord,
        target: @nextStage.name,
        neighbours: @wordNeighbours
    )
  stagesOfEvolution: [
    {name:'cell', bonuses: ['split']}
#    'amoeba' (too hard, nothing's connected to it)
    {name: 'worm', bonuses: ['move', 'swim', 'egg']}
    {name: 'fish', bonuses: ['eye', 'heart', 'gill']}
    {name: 'frog', bonuses: ['leg', 'air', 'land']}
    # nothing's connected to reptile either
    # {name: 'reptile', bonuses: ['heat', 'walk']}
    # {name: 'mammal', bonuses: ['hair', 'milk', 'upright', 'nurse']}
    # {name: 'human', bonuses: ['brain', 'cooking', 'tools']}
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

  currentWord: 'YOU SHOULD NEVER SEE THIS DEFAULT WORD'
  currentBoosters: []
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

  trigger: (eventName, args...) ->
    for callback in (@events[eventName] || [])
      callback(args...)

(($, d3) ->
  game = null

  paintAll = ->
    paintCurrentWord()
    paintCandidateNextWords(game.candidateNextWords)
    paintStatus()

  paintCurrentWord = ->
    letters = d3.selectAll('.current-word').selectAll('.letter').data(game.currentWord.split(''), (d,i)->d+i)
    
    letters.enter()
      .insert('span')
        .attr('class', 'letter')
        .style('opacity', 1e-6)
      .transition().duration(5000)
        .style('opacity', 1)

    letters.text(String)

    fadeOut = letters.exit().transition().duration(5000)
    fadeOut.style('opacity', 1e-6).style('width', 0)
    fadeOut.remove()

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
    d3.select('.canvas > ul').html(replacementHtml)

  paintStatus = ->
    d3.select('dd#next-stage').text(game.nextStage.name)
    d3boosters = d3.select('ul.boosters').selectAll('li').data(game.currentBoosters)
    d3boosters.enter().append('li')
    d3boosters.text(String)
    d3boosters.exit().remove()

  onWordChange = ->
    window.location.hash = '#' + game.currentWord
    paintAll()
    paintCandidateNextWords(game.candidateNextWords)
    $('audio.wordchange')[0].play()

  onWaypointSuggested = (suggestedWaypoint) ->
    hint = d3.select('.hint').data([suggestedWaypoint])
    hint.enter()
      .append('p')
        .attr('class', 'hint')
    hint.exit().remove()
    hint.text (waypoint) ->
      "Try going through '#{waypoint}'"

  onHashChange = ->
    newWord = window.location.hash.replace(/^#*/, '')
    game.advanceToWord(newWord)

  onEvolution = (newStage) ->
    $('.game').attr('data-level', newStage.name)
    $('audio#level-up')[0].play()

  onWonGame = ->
    $('.game')
      .toggleClass('not-yet-won', false)
      .toggleClass('won', true)
    $('.game .win-screen audio')[0].play()

  d3.json 'javascripts/wordneighbours.json', (wordNeighbours) ->
    game = new Game(wordNeighbours)
    game.on 'word.change', onWordChange
    game.on 'evolve', onEvolution
    game.on 'hint.waypoint_suggested', onWaypointSuggested
    game.on 'win', onWonGame
    $(window).on('hashchange', onHashChange) # TODO: I'm sure D3 can register a hashchange handler too
    onWordChange()

# on choose next_word
#   evolve if next_word == target_word
#   health--
#   current_word = selected_word
#   award_bonuses for current_word
#   paint

)(jQuery, d3)

# for word in candidate_next_words
#   maybe = areWordsAdjacent(current_word, word)
#   console.log("Is #{word} close? #{maybe}")
