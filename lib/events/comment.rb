module Events
  class Comment < Event
    PLUS_ONE = ["👍", ":+1:", "+1"]
    RECYCLE = ["♻️", ":recycle:"]

    def process
      case
      when PLUS_ONE.any? { |word| body.include?(word) }
        add_label(:Reviewed)
      when RECYCLE.any? { |word| body.include?(word) }
        remove_label(:Reviewed)
      end
    end

    private

      def body
        payload.comment.body
      end
  end
end
