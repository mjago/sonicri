module PodPicr
  class State
    def initialize(@state_table : Array({st: S, res: A, to: S}))
      @queue = [] of A
      @state = @state_table[0][:st]
    end

    def state
      check = false
      debug_state

      @state_table.each do |st|
        if match_state st[:st]
          check = true
          if match_response st[:res]
            state_to st[:to]
            break
          end
        end
      end
      raise("Error: state (#{@state}) doesn't exist in StateTable!") unless check
      @state
    end

    def action(act : A)
      @queue << act unless act == A::NoAction
    end

    private def match_state(state)
      state == @state
    end

    private def match_response(response)
      response.nil? || done? response
    end

    private def action?
      !@queue.empty?
    end

    private def done?(act)
      if action?
        if @queue.includes?(act)
          @queue.delete(act)
          return true
        end
      end
      false
    end

    private def state_to(state : S)
      @state = state
    end

    private def debug_state
      return
      STDERR.puts "state: #{@state}"
      STDERR.flush
    end
  end
end
