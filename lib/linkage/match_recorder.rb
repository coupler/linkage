module Linkage
  # {MatchRecorder} is responsible for observing {Matcher} for changes and
  # saving matches to a {MatchSet} via {MatchSet#add_match}.
  class MatchRecorder
    # @param matcher [Matcher]
    # @param match_set [MatchSet]
    def initialize(matcher, match_set)
      @matcher = matcher
      @match_set = match_set
    end

    def start
      @matcher.add_observer(self)
      @match_set.open_for_writing
    end

    def update(id_1, id_2, score)
      @match_set.add_match(id_1, id_2, score)
    end

    def stop
      @match_set.close
      @matcher.delete_observer(self)
    end
  end
end
