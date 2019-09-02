# frozen_string_literal: true

class Hello
  def initialize(args)
    @args = args
  end

  def answer
    "answer. args: #{@args.inspect}"
    @args.keys.join(',')
    {}.methods.sort.join
    {}.methods.sort.join
    @args.inspect
    summary = ''
    @args.keys.each do |key|
      summary += "#{key}: #{@args[key]}; "
    end
    summary
  end
end
