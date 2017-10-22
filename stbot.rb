require "./stbots"

class STBot
  @name="stone_minimum"
  @bot

  def initialize
    @bot = MarkovBot.new
  end

  def prepareData
    @bot.prepareData
  end

  def inputSentence(str)
    
  end

  
  def getSentence
    @bot.getSentence
  end
end


