class TransitionMatrix
  def initialize
    @matrix = Hash.new
    @probabilistic_matrix = Hash.new
  end

  def add(from_first, from_second, to)
    from = from_first + ' ' + from_second
    @matrix[from] = Hash.new(0) unless @matrix.has_key? from
    @matrix[from][to] += 1

    @probabilistic_matrix[from] = nil
  end

  def count
    @matrix.inject(0) do |total, (from, to)|
      total + count_of_row(from)
    end
  end

  def count_of_row(word)
    @matrix[word].values.inject(:+)
  end

  def transitions(word)
    @probabilistic_matrix[word] ||= @matrix[word].inject({}) do |matrix, (to_word, to_count)|
      matrix[to_word] = to_count.to_f / count_of_row(word).to_f
      matrix
    end
  end

  def cumulative_transitions(word)
    transitions(word).inject({:matrix => {}, :total => 0.0}) do |prob_set, (to_word, to_prob)|
      prob_set[:matrix][to_word] = Range.new(prob_set[:total], prob_set[:total] + to_prob, true)
      prob_set[:total] += to_prob
      prob_set
    end.fetch(:matrix)
  end

  def keys
    @matrix.keys
  end

  def get_next(word)
    rand = Random.rand
    cumulative_transitions(word).select {|to_word, to_prob| to_prob.cover? rand }.keys.first
  end
end


