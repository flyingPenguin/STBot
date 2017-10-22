require 'natto'
require 'csv'

class MarkovBot
  @target_file = "aozora.txt"
  @formatted_file = "string.txt"
  @formatted_string = ""

  TOP_OF_LINE = "nil_first_of_scentence"
  TOP_OF_LINE_ID = 0
  END_OF_LINE = "nil_end_of_scentence"
  @id_to_word
  @word_to_id
  @h
  @h_id

  def initialize
    @id_to_word = Hash.new(0)
    @word_to_id = Hash.new(0)
    @h_key      = Hash.new(0)
    @h_id       = Hash.new(0)
  end

  def prepareData
    #format_target_file
    #@formatted_string = ExtractionString.getStringFromOutfile
    #analize_morpheme
    #save_model
    load_model
  end

  def format_target_file
    ExtractionString.extraction
  end

  def save_model
    puts "save_model"

    puts "save model_id_word.csv"
    CSV.open("model_id_word.csv", "w") do |csv|
      csv << ["id", "key"]
      @id_to_word.each do |key, value|
        csv << [key, value]
      end
    end

    puts "save model_morpheme.csv"
    CSV.open("model_morpheme.csv", "w") do |csv|
      csv << ["id", "key", "value"]
      @h_key.each do |key, data|
        csv << [data.id, data.key, data.value]
      end
    end

    puts "save model_prevList.csv"
    CSV.open("model_prevList.csv", "w") do |csv|
      csv << ["id", "prevList"]
      @id_to_word.each do |key, value|
        list_data = ""
        @h_id[key].prevList.each do |data|
          str = ""
          if data == nil then
            str = END_OF_LINE
          else
            str = data.id.to_s
          end
          str += "|/|"
          list_data = list_data + str
        end
        csv << [key, list_data]
      end
    end

    puts "save model_nextList.csv"
    CSV.open("model_nextList.csv", "w") do |csv|
      csv << ["id", "nextList"]
      @id_to_word.each do |key, value|
        list_data = ""
        @h_id[key].nextList.each do |data|
          str = ""
          if data == nil then
            str = END_OF_LINE
          else
            str = data.id.to_s
          end
          str += "|/|"
          list_data = list_data + str
        end
        csv << [key, list_data]
      end
    end

    puts "save_model finish"
  end

  def load_model
    puts "load model_id_word.csv"
    CSV.foreach("model_id_word.csv", headers: true) do |data|
      @id_to_word[data["id"].to_i] = data["key"]
      @word_to_id[data["key"]] = data["id"].to_i
    end

    puts "load model_porpheme.csv"
    CSV.foreach("model_morpheme.csv", headers: true) do |data|
      m = Morpheme.new
      m.id = data["id"].to_i
      m.key = data["key"]
      m.value = data["value"].to_i
      @h_id[m.id] = m
      @h_key[m.key] = m
    end

    puts "load model_prevList.csv"
    CSV.foreach("model_prevList.csv", headers: true) do |data|
      list = Array.new
      id_list = data["prevList"].split("|/|")
      id_list.each do |id|
        if id == END_OF_LINE
          list.push(nil)
        else
          list.push(@h_id[id.to_i])
        end
      end
      @h_id[data["id"].to_i].prevList = list
    end

    puts "load model_nextList.csv"
    CSV.foreach("model_nextList.csv", headers: true) do |data|
      list = Array.new
      id_list = data["nextList"].split("|/|")
      id_list.each do |id|
        if id == END_OF_LINE
          list.push(nil)
        else
          list.push(@h_id[id.to_i])
        end
      end
      @h_id[data["id"].to_i].nextList = list
    end

    puts "load_model finish"
  end

  def analize_morpheme
    puts "analize_morpheme"

    nm = Natto::MeCab.new
    top = Morpheme.new
    top.id = 0
    top.key = TOP_OF_LINE
    top.value = 0
    @h_key[top.key] = top
    id = 1
    @formatted_string.each_line do |line|
      prev = top

      if line == "" || line.length <= 1 then
        #puts "blanc line"
        next
      end
      nm.parse(line) do |n|
        if n.surface == "" then
          #puts "blanc morpheme"
          next
        end

        if @h_key.has_key?(n.surface) then
          @h_key[n.surface].value += 1
        else
          w = Morpheme.new
          w.id = id
          w.key = n.surface
          w.value = 1
          @h_key[n.surface] = w
        end

        @h_key[n.surface].prevList.push(prev)
        if prev != nil
          prev.nextList.push(@h_key[n.surface])
        end

        prev = @h_key[n.surface]
        id += 1
      end

      prev.nextList.push(nil) #end of line
    end

    @h_key.each do |key, value|
      @word_to_id[key] = value.id
      @id_to_word[value.id] = key
    end

    @h_key.each do |key, value|
      @h_id[value.id] = @h_key[key]
    end
  end

  def getSentence
    puts "getSentence"
    len = @h_key[TOP_OF_LINE].nextList.length
    #puts "nextList.length: #{len}"
    val = rand(len)
    current_word = @h_key[TOP_OF_LINE].nextList[val].key
    text = current_word

    while true do
      val = rand(@h_key[current_word].nextList.length)
      next_track = @h_key[current_word].nextList[val]
      if next_track == nil
        #puts "next_track is nil"
        break
      end

      current_word = next_track.key
      #puts "current_word; #{current_word}"
      if current_word == nil
        break
      end
      text += current_word
    end
    text
  end
end


class Morpheme
  @id = 0
  @key = ""
  @value = 0
  @prevList
  @nextList

  def initialize
    @prevList = Array.new
    @nextList = Array.new
  end

  attr_accessor :id,:key,:value,:prevList,:nextList
end

class ExtractionString
  @infile = 'aozora.txt'
  @outfile = 'string.txt'

  def self.extraction()
    open(@infile, "r:Windows-31J:UTF-8") do |source|
      open(@outfile, "w") do |data|
        s = source.read
        s = s.gsub(/《[^》]+》/, "")
        s = s.gsub(/［[^］]+］/, "")
        s = s.gsub(/　/, " ")
        s = s.gsub(/。/, "。\n")
        data.print s.gsub(/(\r\n)/, "\n")
      end
    end
  end

  def self.getStringFromOutfile
    text = String.new
    File.open(@outfile, "r") do |source|
      text = source.read
    end
    text
  end
end
