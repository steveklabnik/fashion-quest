class Game

  attr_accessor :state, :helpers, :app_base_path, :path, :config, :player, :characters, :locations, :doors, :props, :turns, :over, :transitions

  include Handles_YAML_Files
  include Handles_Scoring

  def initialize(config, app_base_path, path = 'game/')

    @config        = config
    @app_base_path = app_base_path
    @path          = path

    # helpers is just a generic object which we can extend to add helper functions
    @helpers       = Object.new

    @game = self

    # transitions are sets of triggering conditions and resulting outcomes
    @transitions = load_yaml_file("#{path}transitions.yaml")

    restart(false)

  end

  # helper function to interface game object creation
  def create(object_class, id = false)

    case object_class.name

      when 'Player'

        if !@props || !@locations
          alert('Characters must be defined after player, props, and location.')
        end

        player = Player.new \
          :props => @props,
          :characters => @characters

        player.dead = false

        player

      when 'Door'
        door = Door.new
        door.id = id

        door

      when 'Character'

        if !@locations || !@player || !@props
          alert('Characters must be defined after player, props, and location.')
        end

        character = Character.new \
          :locations => @locations, \
          :player => @player, \
          :props => @props

        character.id = id

        character

      when 'Prop'
        prop = Prop.new
        prop.id = id

        prop

      when 'Location'

        location_config_path = "#{@path}locations"

        location = Location.new(location_config_path)

        location.id = id

        location.path = location_config_path

        location.image_file  = "#{location_config_path}/images/#{id}.jpg"

        location

    end
  end

  def restart(require_confirmation = true, prompt = "Are you sure you want to restart your game?")

    # if confirmation is required, get user input a pop up dialogue
    restart_confirmed = (require_confirmation == true) ? confirm(prompt) : true

    if (require_confirmation)
      #zzzz
    end

    if restart_confirmed

      @turns = 0
      @state = {}
      @over  = false

      @output_text = ''

      @scoring = @config['scoring']
      initialize_scoring(@path)

      setup

    end

    restart_confirmed

  end

  def setup

    @locations  = {}
    @props      = {}
    @doors      = {}
    @characters = {}

    # Include setup logic from file, if one exists
    path_to_setup_logic = @path + 'setup_logic.rb'
    if File.file?(path_to_setup_logic)
      instance_eval(File.read(path_to_setup_logic))
    else
      if @config['setup_logic']
        instance_eval(@config['setup_logic'])
      else
        initialize_locations
        @doors      = initialize_doors
        @props      = initialize_props
        @characters = {}
        @player     = initialize_player
        initialize_characters(@locations, @player, @props)
      end
    end
  end

  def restart_or_exit

    #zzzz

    restart(true, "Would you like to play again?") ? true : exit()

  end

  def elements(name)

    if @doors.has_key?(name)
      return @doors[name]
    end

    if @props.has_key?(name)
      return @props[name]
    end

    if @characters.has_key?(name)
      return @characters[name]
    end

    if @locations.has_key?(name)
      return @locations[name]
    end

  end

  def find_alias(alias_to_find)

    [@doors, @props, @characters].each do |elements|

      if element_alias = find_alias_among(elements, alias_to_find)

        return element_alias
      end
    end

    false

  end

  def find_alias_among(elements, alias_to_find)

    elements.each do |id, element|

      if element.aliases

        element.aliases.each do |element_alias|

          if element_alias == alias_to_find

            # if we found one in player location or inventory, return
            if (element.location == @player.location || element.location == 'player') ||
              (element.respond_to?(:locations) && element.locations.include?(@player.location))

              return element.id
            end
          end
        end
      end
    end

    # we didn't find anything
    false

  end

  def initialize_player

    # player data is stored in YAML as a hash
    player_config_file = "#{path}player/player.yaml"
    player_data = load_yaml_file(player_config_file)

    if player_data

      player = create(Player)
      map_hash_to_object_attributes(player, player_data)

    else

      error('No player data found at ' + player_config_file)

    end

  end

  def initialize_characters(locations, player, props)

    recursive_find_of_yaml_file_data("#{@path}characters").each do |character_data|

      # create objects from hash of object hashes
      character_data.each do |id, character_definition|

        character = Character.new :locations => locations, :player => player, :props => props
        @characters[id] = map_hash_to_object_attributes(character, character_definition)

        # set object id, so it can be read
        @characters[id].id = id

      end

    end

  end

  def initialize_locations

    @locations = {}

    location_config_path = "#{@path}locations"

    recursive_find_of_yaml_file_data(location_config_path).each do |location_data|

      # create objects from hash of object hashes
      location_data.each do |id, location_definition|

        location = create(Location, id)
        @locations[id] = map_hash_to_object_attributes(location, location_definition)

      end
    end

    if @locations.length < 1
      error('No location config files found at ' + location_config_path)
    end

  end

  def initialize_doors

    doors = {}

    # door data is stored in YAML as a hash
    door_config_path = "#{path}doors/doors.yaml"
    door_data = load_yaml_file(door_config_path)

    if door_data
      # create objects from hash of object hashes
      door_data.each do |id, door_definition|
        doors[id] = map_hash_to_object_attributes(Door.new, door_definition)
        doors[id].id = id
        if !doors[id].traits.has_key?('visible')
          doors[id].traits['visible'] = true
        end
      end
    else
      error('No door config files found at ' + door_config_path)
    end

    doors

  end

  def initialize_props

    # prop data is stored in YAML as a hash
    prop_config_path = "#{path}props/props.yaml" 
    prop_data = load_yaml_file(prop_config_path)

    if prop_data
      # create objects from hash of object hashes
      prop_data.each do |id, prop_definition|
        props[id] = map_hash_to_object_attributes(Prop.new, prop_definition)
        props[id].id = id
        if !props[id].traits.has_key?('portable')
          props[id].traits['portable'] = true
        end
        if !props[id].traits.has_key?('visible')
          props[id].traits['visible'] = true
        end
      end
    else
      error('No prop config files found at ' + prop_config_path)
    end

    props

  end

  def map_hash_to_object_attributes(object, hash)

    # use hash key => value to set property object attributes
    hash.each do |attribute, value|
      eval('object.' + attribute.gsub(' ', '_') + ' = value')
    end

    object

  end

  def turn

    output = ''

    @characters.each do |name, character|
      output << character.turn_logic
    end

    @props.each do |name, prop|

      if prop.traits['lit'] && prop.traits['lit'] == true
        if prop.traits['burn_turns'] > 0
          @props[name].traits['burn_turns'] -= 1
        else
          output << "The #{name} has gone out.\n"
          @props[name].traits['lit'] = false
        end
      end

    end

    output << transitions

    @turns += 1

    output

  end

  def save(filename = "#{path}player/saved_game.yaml")

    game_data = {
      'turn'       => @turns,
      'state'      => @state,
      'over'       => @over,

      'player'     => @player,
      'locations'  => @locations,
      'doors'      => @doors,
      'characters' => @characters,
      'props'      => @props
    }

    save_data_as_yaml_file(game_data, filename)

  end

  def load(filename = "#{path}player/saved_game.yaml")

    game_data = load_yaml_file(filename)

    @turn       = game_data['turns']
    @state      = game_data['state']
    @over       = game_data['over']

    @player     = game_data['player']
    @locations  = game_data['locations']
    @doors      = game_data['doors']
    @characters = game_data['characters']
    @props      = game_data['props']

  end

  def not_found(thing)
    "I don't see a #{thing}.\r"
  end

  def prop_located_at(prop, location)

    @props[prop] && @props[prop].location == location

  end

  def transitions

    output = ''

    if @transitions

      # attempt each transition
      @transitions['conditions'].each do |conditions, outcomes|

        effect_outcome = false

        # check each condition in the transition
        conditions.each do |condition|
          if instance_eval(condition)
            effect_outcome = true
          end
        end

        # if a condition was met, effect all outcomes
        if effect_outcome == true

          outcomes.each do |outcome|

            # evaluate outcome
            result = eval(@transitions['outcomes'][outcome])

            # if outcome can be converted to a string, add to output
            if result.to_s
              output << result.to_s
            end
          end
        end

      end
    end

    output

  end

  def attempt_open_item(item, with_prop)

    attempt_open_or_close_item(item, with_prop, 'open')
  end

  def attempt_close_item(item, with_prop)

    attempt_open_or_close_item(item, with_prop, 'close')
  end

  def attempt_open_or_close_item(item, with_prop, open_or_close)

    output = ''

    item_object = (@props[item]) ? @props[item] : @doors[item]

    if item_object.traits.has_key?('opened')
      if (item_object.traits['opened'] && open_or_close == 'open') ||
        (!item_object.traits['opened'] && open_or_close == 'close')
        state = (open_or_close == 'open') ? 'open' : 'closed'
        output << "It's already " + state + ".\n"
      elsif item_object.traits[open_or_close + '_with']
        if with_prop
          if prop_located_at(with_prop, 'player') and item_object.traits[open_or_close + '_with'].index(with_prop)
            output << open(item)
          end
        else
          output << "It won't open. Maybe you need something to " + open_or_close + " it with?\n"
        end
      else
        return (open_or_close == 'open') ? open(item) : close(item)
      end
    else
      output << "You can't " + open_or_close + " the #{item}.\n"
    end

    output

  end

  def open(item)

    if @props[item]
      prop_open(item)
    elsif @doors[item]
      door_open(item)
    else
      error("game.open called on item that isn't a prop or door.")
    end
  end

  def close(item)

    if @props[item]
      prop_close(item)
    elsif @doors[item]
      door_close(item)
    else
      error("game.close called on item that isn't a prop or door.")
    end
  end

  def door_open(door)

    output = ''

    if @doors[door]

      output << "You open #{@doors[door].noun}.\n"

      output << event(@doors[door], 'on_open')

      @doors[door].traits['opened'] = true

    end

    output

  end

  def door_close(door)

    output = ''

    if @doors[door]

      output << "You close #{@doors[door].noun}.\n"

      output << event(@doors[door], 'on_close')

      @doors[door].traits['opened'] = false

    end

    output

  end

  def prop_open(prop)

    output = ''

    if @props[prop]

      output << "You open #{@props[prop].noun}.\n"

      if @props[prop].traits['contains']

        @props[prop].traits['contains'].each do |contained_item|

          if @props[contained_item]

            output << "#{@props[prop].noun_cap} contains #{@props[contained_item].noun_direct}.\n"
            @props[contained_item].location = @player.location

          end
        end

        @props[prop].traits['contains'] = false
      end

      output << event(@props[prop], 'on_open')

      @props[prop].traits['opened'] = true

    end

    output

  end

  def prop_close(prop)

    output = ''

    if @props[prop]

      output << "You close #{@props[prop].noun}.\n"

      output << event(@props[prop], 'on_close')

      @props[prop].traits['opened'] = false

    end

    output

  end

  def event(object, type)

    if object.events && object.events[type]

      event_response = object.events[type]

      begin

        result = instance_eval(event_response)

        return result

      # if evaluation of event response fails, return the response as text
      rescue SyntaxError, NameError

        alert('Error evaluating event response ' + type + ' for ' + object.name)
        return event_response

      end
    end

    # return blank string if no event has happened
    ""

  end

  def prop_located_near_player(prop)

    in_same_room = @props[prop].location == @locations[@player.location].id
    in_inventory = @props[prop].location == 'player'
    return in_same_room || in_inventory

  end

  def if_worn_take_off(prop)

    output = ''

    if @player.wearing.index(prop.id)

      @player.wearing.delete(prop.id)

      output << "(taking off #{prop.noun})\n"

    end

    output
  end

end
