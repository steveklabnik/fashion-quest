Fine-Tuning
===========

Each game's `config.yaml` file allows fine-tuning of a number of elements.

.. list-table:: Game settings
   :widths: 20 80

   * - **Setting**
     - **Description**
   * - title
     - title of the game (displayed in the window bar)
   * - width
     - width of game window
   * - image_height
     - maximum height of images
   * - resizable
     - whether or not the player should be able to resize the game window
   * - startup_message
     - text to display to the player upon startup
   * - background
     - Background image for game
   * - command_condition
     - Ruby logic that determines whether any command should execute
   * - setup_logic
     - Ruby logic to set up game (see demo games for examples)
 
Other elements that can be set in `config.yaml` are explained later in this section.

Scoring
-------

If a game incorporates scoring, player actions can result in score increases that generally serve as a marker of game progress. The standard command `score` will let the player know of his or her current score.

Scoring items are configured in `config.yaml`. An example is shown below.

.. literalinclude:: examples/config_scoring.yaml

Each scoring item has a name and point value. Scoring is triggered using Ruby logic. The Ruby logic `@game.set_score('<name of scoring item>')` will trigger a scoring item. 

Parsing
-------

Fashion Quest includes employs a crude, case-insensitive, parsing mechanism that converts player input into "lexemes": text elements (single words or game element identifiers such as "hat" or "blue hat") that can be compared to command syntax forms.

Here's the basic flow of parsing:

1. Abbreviated commands are expanded
2. Input is broken into lexemes (single words or game element indentiers)
3. Lexemes that match synonyms are replaced
4. Lexemes that match garbage words are deleted
5. Lexemes that are aliases to game element IDs are resolved

Abbreviated Commands
~~~~~~~~~~~~~~~~~~~~

Abbreviated commands reduce the amount of typing the user must do. One popular convention in interactive fiction is allowing a user simply to enter the first letter of the direction (s)he'd like to go in: `n` for `go north`, for example.

The `command_abbreviations.yaml` file, in the `parsing` subdirectory of each game's directory, allows a list of abbreviations for specific command instances to be defined using YAML. An example is shown below.

.. literalinclude:: ../../pirate_adventure/parsing/command_abbreviations.yaml

Command abbreviations can alternatively be specified in `config.yaml`. An example is shown below.

.. literalinclude:: examples/config_abbreviations.yaml

.. note::

   The `command_abbreviations.yaml` file isn't the only place command abbreviation can be specified. Command syntax forms that don't contain parameters, like those of the `inventory` command, allow abbreviations to be stored in the command's syntax forms (`i` for inventory, for example).

Synonyms
~~~~~~~~

Synonyms help reduce the number of command syntax forms needed to support command syntax variations. The `global_synonyms.yaml` file, in the game `parsing` subdirectory of each game's directory, can contain a list of word substitutions defined using YAML. These substitutions get applied to a user's command input.

For example, the word "using" can be replaced with the word "with". This synonym would make the command syntax form "attack <character> with <prop>" work when the player enters the command "attack bear using hat".

Example YAML is shown below.

.. literalinclude:: ../../pirate_adventure/parsing/global_synonyms.yaml

Synonyms can alternatively be specified in `config.yaml`. An example is shown below.

.. literalinclude:: examples/config_synonyms.yaml

Garbage Words
~~~~~~~~~~~~~

Garbage words are words with little or no semantic meaning (like "the" and "a). By removing them from the user's command input we recude the number of command syntax forms needed to support command syntax variations. The `garbage_words.yaml` file, found in the `parsing` subdirectory of each game's directory, can contain a list of words that should be discarded from player input.

Example YAML is shown below.

.. literalinclude:: ../../pirate_adventure/parsing/garbage_words.yaml

Garbage words can alternatively be specified in `config.yaml`. An example is shown below.

.. literalinclude:: examples/config_garbage.yaml

Testing
-------

Testing interactive fiction games can be tedious. To make testing easier Fashion Quest provides a couple of simple tools: walkthrough and transcripts (explained in detail later on).

In addition to these tools, the Shoes `alert` function is handy for confirming logic is being executed. `alert("Hello")` will, for example, pop up a dialog box with the word "Hello". The Shoes `error` function is also handy. `error("Hello")` will write the world "Hello" to the console.

When there are syntax errors in game logic, or other errors that stop game execution, you can often get useful clues by pressing Alt-/ to view the Shoes debugging console.

Walkthroughs
~~~~~~~~~~~~

When a player loads or saves a game, via the built-in `load` and `save` commands, all game element definitions are included in the game save. Because of this, these commands aren't very useful for testing.

Walkthroughs, on the other hand, can save a sequence of commands needed to arrive at a certain point in a game. This makes them useful for functional testing. Walkthrough files are simply a YAML list of commands.

To create a walkthrough, simply start you game and play it until the point at which you'd like your walkthrough to end. Entering the command `save walkthrough` will then allow you to save the walkthrough. When you wish to use a walkthrough, start or restart Fashion Quest and enter the command `load walkthrough`.

An example walkthrough is provides for the "Pirate Adventure Knockoff" demonstration game. It lives in the `pirate_adventure` directory and is named `complete_walkthrough`. It cycles through all the commands needed to win the game. Once the walkthrough has loaded, enter the command `score` and the win will be confirmed.

Transcripts
~~~~~~~~~~~

While walkthroughs are good for confirming nothing is broken, transcripts provide a way to confirm no output in a game has changed.

The built-in command `save transcript` will save the game output to a file. You can then make changes to your game, enter the commands needed to arrive at the point in the game where you originally saved the transcript, and use the built-in command `compare transcript` to compare the game output to the original transcript.
