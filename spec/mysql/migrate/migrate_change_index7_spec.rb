describe 'Ridgepole::Client#diff -> migrate' do
  context 'when change index (length is Numeric) / No update' do
    let(:actual_dsl) do
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.index ["first_name", "last_name"], name: "idx_first_name_last_name", length: <%= cond('< 5.2.0.beta2', '{ first_name: 10, last_name: 10 }', 10) %>, <%= i cond(5.0, using: :btree) %>
        end
      EOS
    end

    let(:expected_dsl) do
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.index ["first_name", "last_name"], name: "idx_first_name_last_name", length: <%= cond('< 5.2.0.beta2', 10, '{ first_name: 10, last_name: 10 }') %>, <%= i cond(5.0, using: :btree) %>
        end
      EOS
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_falsy
      expect(subject.dump).to match_ruby actual_dsl
    }
  end

  context 'when change index (length is Numeric) / Update' do
    let(:actual_dsl) do
      <<-EOS
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
        end
      EOS
    end

    let(:expected_dsl) do
      erbh(<<-EOS)
        create_table "employees", primary_key: "emp_no", force: :cascade do |t|
          t.date   "birth_date", null: false
          t.string "first_name", limit: 14, null: false
          t.string "last_name", limit: 16, null: false
          t.string "gender", limit: 1, null: false
          t.date   "hire_date", null: false
          t.index ["first_name", "last_name"], name: "idx_first_name_last_name", length: <%= cond('< 5.2.0.beta2', 10, '{ first_name: 10, last_name: 10 }') %>, <%= i cond(5.0, using: :btree) %>
        end
      EOS
    end

    let(:actual_dsl_plus_index) do
      actual_dsl.sub(/\bend\b/, erbh(<<-EOS))
          t.index ["first_name", "last_name"], name: "idx_first_name_last_name", length: <%= cond('< 5.2.0.beta2', '{ first_name: 10, last_name: 10 }', 10) %>, <%= i cond(5.0, using: :btree) %>
        end
      EOS
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby actual_dsl_plus_index
    }
  end
end
