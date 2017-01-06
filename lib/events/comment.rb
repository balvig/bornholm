module Events
  class Comment < Event
    PLUS_ONE = ["👍", ":+1:"]
    RECYCLE = ["♻️", ":recycle:"]

    def process
      case
      when PLUS_ONE.any? { |word| body.include?(word) }
        add_label(:Reviewed) if not_self_reviewed?
      when RECYCLE.any? { |word| body.include?(word) }
        remove_label(:Reviewed)
      end
    end

    private

      def comment
        @_comment ||= payload.comment
      end

      def body
        comment.body
      end

      def commenter
        comment.user.login
      end

      def owner
        issue.user.login
      end

      def not_self_reviewed?
        commenter != owner
      end
  end
end
