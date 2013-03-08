require_relative 'spec_helper'

describe "Mutations::ArrayFilter" do

  it "allows arrays" do
    f = Mutations::ArrayFilter.new(:arr)
    filtered, errors = f.filter([1])
    assert_equal [1], filtered
    assert_equal nil, errors
  end

  it "considers non-arrays to be invalid" do
    f = Mutations::ArrayFilter.new(:arr)
    ['hi', true, 1, {:a => "1"}, Object.new].each do |thing|
      filtered, errors = f.filter(thing)
      assert_equal :array, errors
    end
  end

  it "considers nil to be invalid" do
    f = Mutations::ArrayFilter.new(:arr, :nils => false)
    filtered, errors = f.filter(nil)
    assert_equal nil, filtered
    assert_equal :nils, errors
  end

  it "considers nil to be valid" do
    f = Mutations::ArrayFilter.new(:arr, :nils => true)
    filtered, errors = f.filter(nil)
    filtered, errors = f.filter(nil)
    assert_equal nil, errors
  end

  it "lets you specify a class, and has valid elements" do
    f = Mutations::ArrayFilter.new(:arr, :class => Fixnum)
    filtered, errors = f.filter([1,2,3])
    assert_equal nil, errors
    assert_equal [1,2,3], filtered
  end

  it "lets you specify a class as a string, and has valid elements" do
    f = Mutations::ArrayFilter.new(:arr, :class => 'Fixnum')
    filtered, errors = f.filter([1,2,3])
    assert_equal nil, errors
    assert_equal [1,2,3], filtered
  end

  it "lets you specify a class, and has invalid elements" do
    f = Mutations::ArrayFilter.new(:arr, :class => Fixnum)
    filtered, errors = f.filter([1, "bob"])
    assert_equal [nil, :class], errors.symbolic
    assert_equal [1,"bob"], filtered
  end

  it "lets you use a block to supply an element filter" do
    f = Mutations::ArrayFilter.new(:arr) { string }

    filtered, errors = f.filter(["hi", {:stuff => "ok"}])
    assert_nil errors[0]
    assert_equal :string, errors[1].symbolic
  end

  it "lets you array-ize everything" do
    f = Mutations::ArrayFilter.new(:arr, :arrayize => true) { string }

    filtered, errors = f.filter("foo")
    assert_equal ["foo"], filtered
    assert_nil errors
  end

  it "lets you array-ize an empty string" do
    f = Mutations::ArrayFilter.new(:arr, :arrayize => true) { string }

    filtered, errors = f.filter("")
    assert_equal [], filtered
    assert_nil errors
  end

  it "lets you pass integers in arrays" do
    f = Mutations::ArrayFilter.new(:arr) { integer :min => 4 }

    filtered, errors = f.filter([5,6,1,"bob"])
    assert_equal [5,6,1,"bob"], filtered
    assert_equal [nil, nil, :min, :integer], errors.symbolic
  end

  it "lets you pass floats in arrays" do
    f = Mutations::ArrayFilter.new(:float) { float :min => 4.0 }

    filtered, errors = f.filter([5.0,6.0,1.0,"bob"])
    assert_equal [5.0,6.0,1.0,"bob"], filtered
    assert_equal [nil, nil, :min, :float], errors.symbolic
  end

  it "lets you pass booleans in arrays" do
    f = Mutations::ArrayFilter.new(:arr) { boolean }

    filtered, errors = f.filter([true, false, "1"])
    assert_equal [true, false, true], filtered
    assert_equal nil, errors
  end

  it "lets you pass model in arrays" do
    f = Mutations::ArrayFilter.new(:arr) { model :string }

    filtered, errors = f.filter(["hey"])
    assert_equal ["hey"], filtered
    assert_equal nil, errors
  end

  it "lets you pass hashes in arrays" do
    f = Mutations::ArrayFilter.new(:arr) do
      hash do
        required do
          string :foo
          integer :bar
        end

        optional do
          boolean :baz
        end
      end
    end

    filtered, errors = f.filter([{:foo => "f", :bar => 3, :baz => true}, {:foo => "f", :bar => 3}, {:foo => "f"}])
    assert_equal [{:foo=>"f", :bar=>3, :baz=>true}, {:foo=>"f", :bar=>3}, {:foo=>"f"}], filtered

    assert_equal nil, errors[0]
    assert_equal nil, errors[1]
    assert_equal({"bar"=>:required}, errors[2].symbolic)
  end

  it "lets you pass arrays of arrays" do
    f = Mutations::ArrayFilter.new(:arr) do
      array do
        string
      end
    end

    filtered, errors = f.filter([["h", "e"], ["l"], [], ["lo"]])
    assert_equal filtered, [["h", "e"], ["l"], [], ["lo"]]
    assert_equal nil, errors
  end

  it "handles errors for arrays of arrays" do
    f = Mutations::ArrayFilter.new(:arr) do
      array do
        string
      end
    end

    filtered, errors = f.filter([["h", "e", {}], ["l"], [], [""]])
    assert_equal [[nil, nil, :string], nil, nil, [:empty]], errors.symbolic
    assert_equal [[nil, nil, "Array[2] isn't a string"], nil, nil, ["Array[0] can't be blank"]], errors.message
    assert_equal ["Array[2] isn't a string", "Array[0] can't be blank"], errors.message_list
  end

end