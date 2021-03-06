module Parses_Commands

  include Handles_YAML_Files

  def parse(input_text, command_abbreviations, garbage_words, global_synonyms)

    if not input_text.empty?

      # convert to lower case and allow for command abbreviations
      input_text = expand_abbreviated_commands(
        input_text.downcase,
        command_abbreviations
      )

      # prepare lexemes for interpretation as command
      lexemes = parse_out_garbage_lexemes(
        parse_normalize_global_synonyms(
          parse_reference_words(input_text.split(' ')),
          global_synonyms
        ),
        garbage_words
      )

      # replace aliases with IDs
      index = 0
      lexemes.each do |lexeme|

        # if lexeme doesn't refer to a game element and it's an alias then
        # replace lexeme with what alias refers to
        if (element_alias = @game.find_alias(lexeme)) && !@game.elements(lexeme)
          lexemes[index] = element_alias
        end

        index += 1

      end

      # return result of first valid command
      if @commands
        @commands.each do |id, command|

          # we need logic to test for a valid commands first
          # because we want to, before executing command logic,
          # check the global command condition
          if (command.try(lexemes, true))

            output = ''

            # global command condition check
            if @command_condition
              command_condition_result = instance_eval(@command_condition)
              if command_condition_result['message']
                output += command_condition_result['message']
              end
            end

            if !@command_condition ||
              command_condition_result.class != Hash ||
              command_condition_result['success'] != false

              result = command.try(lexemes)
              if result
                return output + result
              end
            elsif output != ''
              return output
            end

          end
        end
      end

      # return error if no command is valid
      return output_error

    end
  end

  def expand_abbreviated_commands(input_text, abbreviations)

    if abbreviations

      abbreviations.each do |abbreviation, expansion|

        if input_text == abbreviation

          return expansion
        end
      end

    else
      error('No abbreviations defined.')
    end

    input_text

  end

  def parse_out_garbage_lexemes(lexemes, garbage_words)

    if garbage_words

      garbage_words.each do |word|
        lexemes.delete(word)
      end

    else

      error('No garbage words defined.')
    end

    lexemes

  end

  def parse_reference_words(words, current_word = 1, level = 1)

    number_of_words = words.length

    # if a multi-word command, look for multi-word prop references
    if number_of_words > 1

      # try using each word as the start word
      while current_word < number_of_words do

        # for each sequence starting with the current
        # word, check for prop reference
        remaining_words = ''
        start_word = current_word - 1

        processing_word = 1

        while start_word < number_of_words do

          if remaining_words.length > 0
            remaining_words << ' '
          end

          remaining_words << words[start_word]

          # only check for references for compound words
          if processing_word > 1

            # if the sequence is a game element reference or alias, replace
            # the component words with the reference as a string
            if @game.elements(remaining_words) != nil || @game.find_alias(remaining_words)

              reference_end_word = current_word + remaining_words.scan(/\ /).length 
              words_after_prop_reference =
                words[reference_end_word, number_of_words - reference_end_word]

              # recurse with new word array to see if more references exist
              new_word_array =
                words[0, start_word - 1] + [remaining_words] + words_after_prop_reference

              level += 1

              return parse_reference_words(new_word_array, 1, level)

            end
          end

          processing_word += 1

          start_word += 1
        end

        current_word += 1
      end
    end

    words
  end
 
  def parse_normalize_global_synonyms(lexemes, synonyms)

    if synonyms

      key = 0
      lexemes.each do |word|
        synonyms.each do |synonym,normalized|
          if word == synonym
            lexemes[key] = normalized
          end
        end
        key += 1
      end
    else

      error('Synonyms not defined.')
    end

    lexemes
  end

end
