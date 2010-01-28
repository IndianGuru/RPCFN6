require '03_AlekseyGureiev/utils' # edited for unit test by ashbb

# Single swap operation. It knows what move from one queue to another and
# what will be the delta between those queues after the operation.
class Swap

  attr_reader :delta

  def initialize(from_q1, from_q2, current_delta)
    @from_q1 = from_q1
    @from_q2 = from_q2
    @delta   = (current_delta + 2 * (from_q2.sum - from_q1.sum)).abs
  end
  
  # Applies the swap
  def apply(q1, q2)
    @from_q1.each do |j|
      q2 << q1.delete_at(q1.index(j))
    end

    @from_q2.each do |j|
      q1 << q2.delete_at(q2.index(j))
    end
  end
end
