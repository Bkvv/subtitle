require_relative "../allfather"
require_relative "../scc"
require "nokogiri"

module CommonUtils

  CREDITS = "Credits: Autogenerated by subtitle rubygem".freeze

  # 
  # Method to create the file with basic header informations which can be 
  # further updated with the transformed caption details by respective
  # implementations
  #
  # * +type+          - Target caption type. Refer to AllFather::TYPE_SCC type constants
  # * +output_file+   - Creates this output_file to which type specific
  #  information would be dumped into
  # * +target_lang+   - Target lang of the output_file
  #
  # ==== Returns
  # true if the file is created with right headers and false otherwise
  #
  def create_file(type, output_file, target_lang)
    file = nil
    done = false
    begin
      # Create the file in overwrite mode
      file = File.open(output_file, "w")

      # Dump the initial info into the file to start off with
      case type
      when AllFather::TYPE_SCC
        file.write("Scenarist_SCC V1.0\n\n")

      when AllFather::TYPE_SRT
        file.write("NOTE #{CREDITS}\n\n")

      when AllFather::TYPE_VTT
        file.write("WEBVTT\n\n")
        file.write("NOTE #{CREDITS}\n\n")

      when AllFather::TYPE_TTML
        target_lang ||= ""
        # TODO: Move this to a template file and load from there !!
        data = <<-EOF
<tt xml:lang="" xmlns="http://www.w3.org/ns/ttml">
  <head>
    <metadata xmlns:ttm="http://www.w3.org/ns/ttml#metadata">
      <ttm:desc>#{CREDITS}</ttm:desc>
    </metadata>
  </head>
  <body>
    <div xml:lang=\"#{target_lang}\">
          EOF
          file.write(data)

      when AllFather::TYPE_DFXP
        target_lang ||= ""
        data = <<-EOF
<tt xml:lang="" xmlns="http://www.w3.org/2004/11/ttaf1">
  <head>
    <meta xmlns:ttm="http://www.w3.org/2004/11/ttaf1#metadata">
      <ttm:desc>#{CREDITS}</ttm:desc>
    </metadata>
  </head>
  <body>
    <div xml:lang=\"#{target_lang}\">
          EOF
          file.write(data)
      else
        raise AllFather::InvalidInputException.new("Not a valid type; Failed to create output file for type #{type}")
      end
      done = true
    ensure
      file.close if file rescue nil
    end
    done
  end

  # 
  # Method to return a valid extension for a given caption type
  # Refer to `AllFather#VALID_FILES`
  #
  # * +type+  - Must be one of the valid type defined in `AllFather`
  #
  # ====Raises
  # InvalidInputException if a valid type is not provided
  #
  def extension_from_type(type)
    case type 
    when AllFather::TYPE_SCC
      return AllFather::VALID_FILES[0]
    when AllFather::TYPE_SRT
      return AllFather::VALID_FILES[1]
    when AllFather::TYPE_VTT
      return AllFather::VALID_FILES[2]
    when AllFather::TYPE_TTML
      return AllFather::VALID_FILES[3]
    when AllFather::TYPE_DFXP
      return AllFather::VALID_FILES[4]
    else
      raise AllFather::InvalidInputException.new("Not a valid type; Failed to create output file for type #{type}")
    end
  end

  #
  # Method to return the cue info of the caption based on the model
  # and target caption type which can be used by the caller's transformation routine
  #
  def new_cue(model, target_type, last_cue = false)
    message = nil
    case target_type
    when AllFather::TYPE_SCC
      start_unit = model.start_time_units
      h = start_unit[0].to_s.rjust(2, "0")
      m = start_unit[1].to_s.rjust(2, "0")
      s = start_unit[2].to_s.rjust(2, "0")
      ms = start_unit[3]
      if ms > 100 
        ms = ms / 10
      end
      # TODO: Might have to strip off non-english characters here
      message = "#{h}:#{m}:#{s}:#{ms} " + SCC.encode(model.message)
    when AllFather::TYPE_VTT, AllFather::TYPE_SRT
      start_unit = model.start_time_units
      end_unit = model.end_time_units
      message = ""
      if model.sequence
        message = model.sequence + "\n"
      end
      delimiter_added = false
      [start_unit, end_unit].each do |unit|
        h = unit[0].to_s.rjust(2, "0")
        m = unit[1].to_s.rjust(2, "0")
        s = unit[2].to_s.rjust(2, "0")
        ms = unit[3]
        if ms < 100
          ms = ms.to_s.rjust(3, "0")
        end
        if target_type == AllFather::TYPE_VTT
          message << "#{h}:#{m}:#{s}:#{ms}"
        else
          message << "#{h}:#{m}:#{s},#{ms}"
        end
        unless delimiter_added
          message << " --> "
          delimiter_added = true
        end
      end
      message << "\n"
      message << model.message
      message << "\n"
    when AllFather::TYPE_TTML, AllFather::TYPE_DFXP
      start_unit = model.start_time_units
      end_unit = model.end_time_units
      h = start_unit[0].to_s.rjust(2, "0")
      m = start_unit[1].to_s.rjust(2, "0")
      s = start_unit[2].to_s.rjust(2, "0")
      ms = start_unit[3]
      begin_time = "#{h}:#{m}:#{s}"
      begin_time << ".#{ms}" if ms > 0
      h = end_unit[0].to_s.rjust(2, "0")
      m = end_unit[1].to_s.rjust(2, "0")
      s = end_unit[2].to_s.rjust(2, "0")
      ms = end_unit[3]
      end_time = "#{h}:#{m}:#{s}"
      end_time << ".#{ms}" if ms > 0
      message = "<p begin=\"#{begin_time}\" end=\"#{end_time}\">#{model.message}</p>"
      message << "</div>\n</body>\n</tt>" if last_cue
    end
    message
  end

  def time_details(time_stamp, type)
    h = m = s = ms = nil
    elapsed_seconds = nil
    case type 
    when AllFather::TYPE_SCC
      tokens = time_stamp.split(":")
      h = tokens[0].to_i
      m = tokens[1].to_i
      s = tokens[2].to_i
      ms = tokens[3].to_i
    when AllFather::TYPE_SRT
      tokens =time_stamp.split(",")
      ms = tokens[1].to_i
      tokens = tokens[0].split(":")
      h = tokens[0].to_i
      m = tokens[1].to_i
      s = tokens[2].to_i
    when AllFather::TYPE_VTT
      tokens =time_stamp.split(".")
      ms = tokens[1].to_i
      tokens = tokens[0].split(":")
      if tokens.size == 2
        h = 0
        m = tokens[0].to_i
        s = tokens[1].to_i
      else
        h = tokens[0].to_i
        m = tokens[1].to_i
        s = tokens[2].to_i
      end
    when AllFather::TYPE_TTML, AllFather::TYPE_DFXP
      # We support only clock-time without framerate / tickrate and only media timebase
      # For offset hence we don't support frames / ticks
      tokens = time_stamp.split(":")
      if tokens.size > 1
        if tokens.size > 3
          # This is specified with frames and/or subframes. Unsupported
          raise AllFather::InvalidInputException.new("TTML file with clock-time referencing frames / ticks is unsupported")
        end
        h = tokens[0].to_i
        m = tokens[1].to_i
        ms_tokens = tokens[2].split(".")
        if ms_tokens.size == 1
          ms = 0
        else
          ms = ms_tokens[1].to_i
        end
        s = ms_tokens[0].to_i
      else
        # Parsing in offset mode
        if time_stamp.end_with?("ms")
          unit = "ms"
          time_with_no_unit = time_stamp[0, time_stamp.size - 2]
        else
          unit = time_stamp[time_stamp.size - 1]
          time_with_no_unit = time_stamp[0, time_stamp.size - 1]
        end
        case unit 
        when "m"
          time_with_no_unit = time_with_no_unit.to_f * 60
        when "h"
          time_with_no_unit = time_with_no_unit.to_f * (60 * 60)
        when "s"
          # do nothing
        when "ms"
          time_with_no_unit = time_with_no_unit.to_f / 1000.0
        else
          # Fail out f / t
          raise AllFather::InvalidInputException.new("TTML file with offset-time referencing frames / ticks is unsupported")
        end
        tokens = time_with_no_unit.to_s.split(".")
        h = m = 0
        if tokens.size == 1
          s = time_with_no_unit
          ms = 0
        else
          s = tokens[0].to_i
          ms = tokens[1].to_i
        end
        h = s / 3600
        m = (s / 60) % 60
        s = s % 60
      end
    end
    elapsed_seconds = (h * 60 * 60) + (m * 60) + s
    return [h, m, s, ms, elapsed_seconds]
  end

  def write_cue(model, file_map, last_cue = false)
    file_map.each do |type, file_path|
      File.open(file_path, "a") do |f|
        f.puts new_cue(model, type, last_cue)
      end
    end
    if last_cue
      # Pretty print the output for ttml & dfxp
      file_map.each do |type, file_path|
        next unless [AllFather::TYPE_DFXP, AllFather::TYPE_TTML].include?(type)
        file = File.open(file_path, "r")
        xml_doc = Nokogiri::XML(file, &:noblanks)
        File.write(file_path, xml_doc.to_s)
      end
    end
  end
end