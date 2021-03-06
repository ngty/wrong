require "./test/test_helper"
require "wrong/sexp_ext"

describe Sexp do
  describe "#deep_clone" do
    it "deeply duplicates the sexp" do
      original = RubyParser.new.parse("x == 5")
      duplicate = original.deep_clone
      assert(original.object_id != duplicate.object_id)
      assert(original[1].object_id != duplicate[1].object_id)
      assert(original[1][3].object_id != duplicate[1][3].object_id)
      assert(original[3].object_id != duplicate[3].object_id)
    end
  end

  def parse(ruby)
    RubyParser.new.parse(ruby)
  end

  describe "#to_ruby" do
    it "converts the sexp to ruby code" do
      sexp = parse("x == 5")
      assert sexp.to_ruby == "(x == 5)"
    end

    it "leaves the original sexp alone" do
      sexp = parse("x == 5")
      assert sexp.to_ruby == "(x == 5)"
      assert sexp.to_ruby == "(x == 5)" # intended
    end
  end

  describe "#assertion? with a question mark" do
    it "matches an sexp that looks like assert { }" do
      sexp = parse("assert { true }")
      assert sexp.assertion?
    end

    it "matches an sexp that looks like assert(message) { }" do
      sexp = parse("assert('hi') { true }")
      assert sexp.assertion?
    end

    it "matches an sexp that looks like deny { }" do
      sexp = parse("deny { false }")
      assert sexp.assertion?
    end

    it "doesn't match an sexp that calls assert without a block" do
      sexp = parse("assert(true)")
      assert !sexp.assertion?
    end

    it "doesn't match a normal sexp" do
      sexp = parse("x == 5")
      assert !sexp.assertion?
    end
  end

  describe "#assertion" do
    it "matches a top-level sexp that looks like assert { }" do
      sexp = parse("assert { true }")
      code = sexp.assertion.to_ruby
      assert code == "assert { true }"
    end

    it "matches a nested sexp that looks like assert { }" do
      sexp = parse("nesting { assert { true } }")
      code = sexp.assertion.to_ruby
      assert code == "assert { true }"
    end

    it "matches the first nested sexp that looks like assert { }" do
      sexp = parse("nesting { assert { true } or assert { false } }")
      code = sexp.assertion.to_ruby
      assert code == "assert { true }"
    end
  end

end
