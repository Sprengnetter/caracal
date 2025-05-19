require 'spec_helper'

describe Caracal::Core::Models::ParagraphModel do
  subject do
    described_class.new content: 'Lorem ipsum dolor....' do
      style       'Fancy'
      align       :right
      color       '666666'
      size        20
      bold        false
      italic      false
      underline   true
      bgcolor     'cccccc'
      keep_next   true
    end
  end


  #-------------------------------------------------------------
  # Configuration
  #-------------------------------------------------------------

  describe 'configuration tests' do

    # accessors
    describe 'accessors' do
      it { expect(subject.paragraph_style).to eq 'Fancy' }
      it { expect(subject.paragraph_align).to eq :right }
      it { expect(subject.paragraph_color).to eq '666666' }
      it { expect(subject.paragraph_size).to eq 20 }
      it { expect(subject.paragraph_bold).to eq false }
      it { expect(subject.paragraph_italic).to eq false }
      it { expect(subject.paragraph_underline).to eq true }
      it { expect(subject.paragraph_bgcolor).to eq 'cccccc' }
      it { expect(subject.paragraph_keep_next).to eq true }
    end

  end


  #-------------------------------------------------------------
  # Public Methods
  #-------------------------------------------------------------

  describe 'public method tests' do

    #=============== GETTERS ==========================

    # .runs
    describe '.runs' do
      it { expect(subject.runs).to be_a(Array) }
    end

    # .run_attributes
    describe '.run_attributes' do
      let(:expected) { { color: '666666', hide_mark: nil, size: 20, bold: false, italic: false, underline: true, bgcolor: 'cccccc' } }

      it { expect(subject.run_attributes.to_h).to eq expected }
    end


    #=============== SETTERS ==========================

    # booleans
    describe '.bold' do
      before { subject.bold(true) }

      it { expect(subject.paragraph_bold).to eq true }
    end
    describe '.italic' do
      before { subject.italic(true) }

      it { expect(subject.paragraph_italic).to eq true }
    end
    describe '.keep_next' do
      before { subject.keep_next(true) }

      it { expect(subject.paragraph_keep_next).to eq true }
    end
    describe '.underline' do
      before { subject.underline(true) }

      it { expect(subject.paragraph_underline).to eq true }
    end

    # integers
    describe '.size' do
      before { subject.size(24) }

      it { expect(subject.paragraph_size).to eq 24 }
    end

    # strings
    describe '.bgcolor' do
      before { subject.bgcolor('dddddd') }

      it { expect(subject.paragraph_bgcolor).to eq 'dddddd' }
    end
    describe '.color' do
      before { subject.color('999999') }

      it { expect(subject.paragraph_color).to eq '999999' }
    end
    describe '.style' do
      before { subject.style('Dummy') }

      it { expect(subject.paragraph_style).to eq 'Dummy' }
    end

    # symbols
    describe '.align' do
      before { subject.align(:center) }

      it { expect(subject.paragraph_align).to eq :center }
    end


    #=============== SUB-METHODS ==========================

    # .link
    describe '.link' do
      let!(:length) { subject.runs.length }

      before { subject.link 'Text', 'https://www.duckduckgo.com' }

      it { expect(subject.runs.size).to eq length + 1 }
    end

    # .br
    describe '.br' do
      let!(:length) { subject.runs.length }

      before { subject.br }

      it { expect(subject.runs.size).to eq length + 1 }
    end

    # .text
    describe '.text' do
      let!(:length) { subject.runs.length }

      before { subject.text 'Text' }

      it { expect(subject.runs.size).to eq length + 1 }
    end

    # .bookmark
    describe '.bookmark_start' do
      let!(:length) { subject.runs.length }

      before { subject.bookmark_start(name:'abc')}

      it { expect(subject.runs.size).to eq length + 1 }
    end

    describe '.bookmark_end' do
      let!(:length) { subject.runs.length }

      before { subject.bookmark_end }

      it { expect(subject.runs.size).to eq length + 1 }
    end


    #=============== VALIDATION ===========================

    describe '.valid?' do
      describe 'when at least one run exists' do
        before do
          allow(subject).to receive(:runs).and_return(['a'])
        end

        it { expect(subject.valid?).to eq true }
      end
      describe 'when no runs exist' do
        before do
          allow(subject).to receive(:runs).and_return([])
        end

        it { expect(subject.valid?).to eq false }
      end
    end

  end


  #-------------------------------------------------------------
  # Private Methods
  #-------------------------------------------------------------

  describe 'private method tests' do

    # .option_keys
    describe '.option_keys' do
      let(:actual)   { subject.send(:option_keys).sort }
      let(:expected) { [:align, :bgcolor, :bgstyle, :bold, :border, :border_color, :border_line, :border_size, :border_spacing, :border_theme_color, :bottom, :bottom, :color, :content, :italic, :keep_lines, :keep_next, :left, :line, :right, :size, :style, :tabs, :theme_bgcolor, :theme_color, :top, :top, :underline, :widow_control, :border_bottom, :border_horizontal, :border_vertical, :border_top, :border_left, :border_right, :whitespace, :vertical_align, :strike, :small_caps, :caps, :rtl, :highlight_color, :font, :hide_mark].sort }

      it { expect(actual).to eq expected }
    end

  end

end
