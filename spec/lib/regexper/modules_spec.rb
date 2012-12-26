require "spec_helper"

describe "Regexper modules" do

  def match_for(regexp)
    Regexper.parse(regexp).content[0].content[0]
  end

  describe Regexper::Regexp do

    before :each do
      @regexp = Regexper.parse('test1|test2')
    end

    describe "#content" do

      it "returns an array of matches" do
        @regexp.content.map(&:text_value).should == ['test1', 'test2']
      end

    end

    describe "#to_obj" do

      it "returns an object with :type of :regexp" do
        @regexp.to_obj[:type].should == :regexp
      end

      it "includes the content as :content" do
        obj = @regexp.to_obj
        obj[:content][0][:content].should == [{ :type => :literal, :content => 'test1' }]
        obj[:content][1][:content].should == [{ :type => :literal, :content => 'test2' }]
      end

    end

  end

  describe Regexper::Match do

    def anchor_start
      Regexper.parse('^anchor_start').content[0]
    end

    def anchor_end
      Regexper.parse('anchor_end$').content[0]
    end

    def unanchored
      Regexper.parse('unanchored').content[0]
    end

    def other_content
      Regexper.parse('other\\scontent\\!').content[0]
    end

    describe "#anchor_start?" do

      it "returns true if the match is anchored to the start of line" do
        anchor_start.anchor_start?.should == true
      end

      it "returns false if the match is not anchored to the start of line" do
        unanchored.anchor_start?.should == false
      end

    end

    describe "#anchor_end?" do

      it "returns true if the match is anchored to the end of line" do
        anchor_end.anchor_end?.should == true
      end

      it "returns false if the match is not anchored to the end of line" do
        unanchored.anchor_end?.should == false
      end

    end

    describe "#content" do

      it "returns the content of match as an array" do
        unanchored.content.map(&:to_obj).should == [
          { :type => :literal, :content => 'u'},
          { :type => :literal, :content => 'n'},
          { :type => :literal, :content => 'a'},
          { :type => :literal, :content => 'n'},
          { :type => :literal, :content => 'c'},
          { :type => :literal, :content => 'h'},
          { :type => :literal, :content => 'o'},
          { :type => :literal, :content => 'r'},
          { :type => :literal, :content => 'e'},
          { :type => :literal, :content => 'd'}
        ]
      end

    end

    describe "#to_obj" do

      it "returns an object with :type of :match" do
        unanchored.to_obj[:type].should == :match
      end

      it "includes a :start value for #anchor_start?" do
        anchor_start.to_obj[:start].should == true
        unanchored.to_obj[:start].should == false
      end

      it "includes a :end value for #anchor_end?" do
        anchor_end.to_obj[:end].should == true
        unanchored.to_obj[:end].should == false
      end

      it "includes the content as :content" do
        obj = other_content.to_obj
        obj[:content][0][:content].should == 'other'
        obj[:content][1][:content].should == :white_space
        obj[:content][2][:content].should == 'content!'
      end

    end

  end

  describe Regexper::MatchRepetition do

    def repeat_any
      match_for('a*')
    end

    def repeat_required
      match_for('b+')
    end

    def repeat_optional
      match_for('c?')
    end

    def repeat_full
      match_for('d{1,2}')
    end

    def repeat_at_least
      match_for('e{1,}')
    end

    def repeat_up_to
      match_for('f{,2}')
    end

    def repeat_exact
      match_for('g{2}')
    end

    def repeat_non_greedy
      match_for('h*?')
    end

    describe "#content" do

      it "returns the content of the match" do
        repeat_any.content.text_value.should == 'a'
        repeat_required.content.text_value.should == 'b'
      end

    end

    describe "#to_obj" do

      it "returns an object with :type of :repetition" do
        repeat_any.to_obj[:type].should == :repetition
      end

      it "includes the content as :content" do
        repeat_any.to_obj[:content].should == {
          :type => :literal,
          :content => 'a'
        }
      end

      describe "the :greedy value" do

        it "is true for greedy matches" do
          repeat_any.to_obj[:greedy].should == true
        end

        it "is false for non-greedy matches" do
          repeat_non_greedy.to_obj[:greedy].should == false
        end

      end

      describe "the :repeat_count value" do

        it "is :any for matches using *" do
          repeat_any.to_obj[:repeat_count].should == :any
        end

        it "is :required for matches using +" do
          repeat_required.to_obj[:repeat_count].should == :required
        end

        it "is :optional for matches using ?" do
          repeat_optional.to_obj[:repeat_count].should == :optional
        end

        it "has a :stop value for repetition specs with an upper bound" do
          repeat_up_to.to_obj[:repeat_count][:stop].should == 2
          repeat_full.to_obj[:repeat_count][:stop].should == 2
        end

        it "has a :start value for repetition specs with a lower bound" do
          repeat_at_least.to_obj[:repeat_count][:start].should == 1
          repeat_full.to_obj[:repeat_count][:start].should == 1
        end

        it "is a number for specs with a specific repetition count" do
          repeat_exact.to_obj[:repeat_count].should == 2
        end

      end

    end

  end

  describe Regexper::MatchSubexp do

    def capturing
      match_for('(capture)')
    end

    def noncapturing
      match_for('(?:no capture)')
    end

    def positive
      match_for('(?=positive lookahead)')
    end

    def negative
      match_for('(?!negative lookahead)')
    end

    describe "#content" do

      it "returns an array of matches" do
        capturing.content.map(&:text_value).should == ['capture']
      end

    end

    describe "#kind" do

      it "is :capture for capturing sub-expressions" do
        capturing.kind.should == :capture
      end

      it "is :no_capture for non-capturing sub-expressions" do
        noncapturing.kind.should == :no_capture
      end

      it "is :positive_lookahead for positive lookahead sub-expressions" do
        positive.kind.should == :positive_lookahead
      end

      it "is :negative_lookahead for negative lookahead sub-expressions" do
        negative.kind.should == :negative_lookahead
      end

    end

    describe "#to_obj" do

      it "returns an object with :type of :subexp" do
        capturing.to_obj[:type].should == :subexp
      end

      it "includes the content as :content" do
        capturing.to_obj[:content][0][:content].should == [
          { :type => :literal, :content => 'capture' }
        ]
      end

      describe "the :kind value" do

        it "is :capture for capturing sub-expressions" do
          capturing.to_obj[:kind].should == :capture
        end

        it "is :no_capture for non-capturing sub-expressions" do
          noncapturing.to_obj[:kind].should == :no_capture
        end

        it "is :positive_lookahead for a positive lookahead sub-expression" do
          positive.to_obj[:kind].should == :positive_lookahead
        end

        it "is :negative_lookahead for a negative lookahead sub-expression" do
          negative.to_obj[:kind].should == :negative_lookahead
        end

      end

    end

  end

  describe Regexper::MatchCharset do

    def charset
      match_for('[abc]')
    end

    def inverted
      match_for('[^abc]')
    end

    def complete
      match_for('[abc1-9\\b]')
    end

    describe "#content" do

      it "returns an array of values to match" do
        charset.content.map(&:to_obj).should == [
          { :type => :literal, :content => 'a' },
          { :type => :literal, :content => 'b' },
          { :type => :literal, :content => 'c' }
        ]
      end

    end

    describe "#inverted?" do

      it "returns true if the character set is inverted" do
        inverted.inverted?.should == true
      end

      it "returns false if the character set is not inverted" do
        charset.inverted?.should == false
      end

    end

    describe "#to_obj" do

      it "returns an object with :type of :charset" do
        charset.to_obj[:type].should == :charset
      end

      it "includes the content as :content" do
        obj = complete.to_obj
        obj[:content][0].should == {
          :type => :literal,
          :content => 'a'
        }
        obj[:content][1].should == {
          :type => :literal,
          :content => 'b'
        }
        obj[:content][2].should == {
          :type => :literal,
          :content => 'c'
        }
        obj[:content][3].should == {
          :type => :range,
          :start => '1',
          :stop => '9'
        }
        obj[:content][4].should == {
          :type => :escaped,
          :content => :backspace
        }
      end

      describe "the :inverted value" do

        it "is true for an inverted character set" do
          inverted.to_obj[:inverted].should == true
        end

        it "is false for a non-inverted character set" do
          charset.to_obj[:inverted].should == false
        end

      end


    end

  end

  describe "special characters and escapes" do

    it "supports '.' as :any_character" do
      match_for('.').to_obj.should == :any_character
    end

    it "supports \\b as :word_boundary escape" do
      match_for('\\b').to_obj.should == { :type => :escaped, :content => :word_boundary }
    end

    it "supports \\B as :non_word_boundary escape" do
      match_for('\\B').to_obj.should == { :type => :escaped, :content => :non_word_boundary }
    end

    it "supports \\d as :digit escape" do
      match_for('\\d').to_obj.should == { :type => :escaped, :content => :digit }
    end

    it "supports \\D as :non_digit escape" do
      match_for('\\D').to_obj.should == { :type => :escaped, :content => :non_digit }
    end

    it "supports \\f as :form_feed escape" do
      match_for('\\f').to_obj.should == { :type => :escaped, :content => :form_feed }
    end

    it "supports \\n as :line_feed escape" do
      match_for('\\n').to_obj.should == { :type => :escaped, :content => :line_feed }
    end

    it "supports \\r as :carriage_return escape" do
      match_for('\\r').to_obj.should == { :type => :escaped, :content => :carriage_return }
    end

    it "supports \\s as :white_space escape" do
      match_for('\\s').to_obj.should == { :type => :escaped, :content => :white_space }
    end

    it "supports \\S as :non_white_space escape" do
      match_for('\\S').to_obj.should == { :type => :escaped, :content => :non_white_space }
    end

    it "supports \\t as :tab escape" do
      match_for('\\t').to_obj.should == { :type => :escaped, :content => :tab }
    end

    it "supports \\v as :vertical_tab escape" do
      match_for('\\v').to_obj.should == { :type => :escaped, :content => :vertical_tab }
    end

    it "supports \\w as :word escape" do
      match_for('\\w').to_obj.should == { :type => :escaped, :content => :word }
    end

    it "supports \\W as :non_word escape" do
      match_for('\\W').to_obj.should == { :type => :escaped, :content => :non_word }
    end

    it "supports \\cX as :control code escape" do
      match_for('\\cX').to_obj.should == {
        :type => :escaped,
        :content => { :type => :control, :code => 'X' }
      }
    end

    it "supports \\xNN as :hex code escape" do
      match_for('\\x1a').to_obj.should == {
        :type => :escaped,
        :content => { :type => :hex, :code => '1A' }
      }
    end

    it "supports \\uNNNN as :unicode escape" do
      match_for('\\u12ef').to_obj.should == {
        :type => :escaped,
        :content => { :type => :unicode, :code => '12EF' }
      }
    end

  end

end
