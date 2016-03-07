class A
  def ans; 42; end

  def pls(a, b)
    a + b
  end
end

describe A do
  let(:a) { A.new }

  it "has 42" do
    expect(a.ans).to eq(42)
  end

  it "sums" do
    expect(a.pls(11, 15)).to eq(25)
  end
end
