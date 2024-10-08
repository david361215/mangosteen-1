require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource "账目" do
  let(:current_user) { create :user }
  let(:auth) { "Bearer #{current_user.generate_jwt}" }
  get "/api/v1/items" do
    authentication :basic, :auth
    parameter :page, '页码'
    parameter :created_after, '创建时间起点（筛选条件）' 
    parameter :created_before, '创建时间终点（筛选条件）' 
    with_options :scope => :resources do
      response_field :id, 'ID'
      response_field :amount, "金额（单位：分）"
    end
    let(:created_after) { Time.now - 10.days }
    let(:created_before) { Time.now + 10.days }
    example "获取账目" do
      user = current_user
      tag = create :tag, user: user
      create_list :item, 25, amount: 100, happened_at: '2020-10-30', tag_ids: [tag.id], user: user
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resources'].size).to eq Item.default_per_page
    end
  end

  post "/api/v1/items" do
    authentication :basic, :auth
    parameter :amount, '金额（单位：分）', required: true
    parameter :kind, '类型', required: true, enum: ['expense', 'income']
    parameter :happened_at, '发生时间', required: true
    parameter :tag_ids, '标签列表（只传ID）', required: true
    with_options :scope => :resource do
      response_field :id
      response_field :amount
      response_field :kind
      response_field :happened_at
      response_field :tag_ids
    end
    let(:amount) { 9900 }
    let(:kind) { 'expense' }
    let(:happened_at) { '2020-10-30T00:00:00+08:00' }
    let(:tags) { (0..1).map{create :tag, user: current_user} }
    let(:tag_ids) { tags.map(&:id) }
    example "创建账目" do
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['resource']['amount']).to eq amount
    end
  end

  get "/api/v1/items/summary" do
    authentication :basic, :auth
    parameter :happened_after, '时间起点', required: true
    parameter :happened_before, '时间终点', required: true
    parameter :kind, '账目类型', enum: ['expense', 'income'], required: true
    parameter :group_by, '分组依据', enum: ['happened_at', 'tag_id'], required: true
    response_field :groups, '分组信息'
    response_field :total, "总金额（单位：分）"
    let(:happened_after) { '2018-01-01' }
    let(:happened_before) { '2019-01-01' }
    let(:kind) { 'expense' }
    example "统计信息（按happened_at分组）" do
      user = current_user
      tag = create :tag, user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-20T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-20T00:00:00+08:00', user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-19T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-19T00:00:00+08:00', user: user
      do_request group_by: 'happened_at'
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['groups'].size).to eq 3
      expect(json['groups'][0]['happened_at']).to eq '2018-06-18'
      expect(json['groups'][0]['amount']).to eq 300
      expect(json['groups'][1]['happened_at']).to eq '2018-06-19'
      expect(json['groups'][1]['amount']).to eq 300
      expect(json['groups'][2]['happened_at']).to eq '2018-06-20'
      expect(json['groups'][2]['amount']).to eq 300
      expect(json['total']).to eq 900
    end

    example "统计信息（按tag_id分组）" do
      user = current_user
      tag1 = create :tag, user: user
      tag2 = create :tag, user: user
      tag3 = create :tag, user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag1.id, tag2.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'expense', tag_ids: [tag2.id, tag3.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 300, kind: 'expense', tag_ids: [tag3.id, tag1.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      do_request group_by: 'tag_id'
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['groups'].size).to eq 3
      expect(json['groups'][0]['tag_id']).to eq tag3.id
      expect(json['groups'][0]['amount']).to eq 500
      expect(json['groups'][1]['tag_id']).to eq tag1.id
      expect(json['groups'][1]['amount']).to eq 400
      expect(json['groups'][2]['tag_id']).to eq tag2.id
      expect(json['groups'][2]['amount']).to eq 300
      expect(json['total']).to eq 600
    end
  end

  get "/api/v1/items/balance" do
    authentication :basic, :auth
    parameter :happened_after, '时间起点', required: true
    parameter :happened_before, '时间终点', required: true
    response_field :income, '总收入'
    response_field :expense, "总支出"
    response_field :balance, "净收入"
    let(:happened_after) { '2018-01-01' }
    let(:happened_before) { '2019-01-01' }
    example "获取账目总收入、总支出、净收入" do
      user = current_user
      tag = create :tag, user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-18T00:00:00+08:00', user: user
      create :item, amount: 100, kind: 'expense', tag_ids: [tag.id], happened_at: '2018-06-20T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'income', tag_ids: [tag.id], happened_at: '2018-06-20T00:00:00+08:00', user: user
      create :item, amount: 100, kind: 'income', tag_ids: [tag.id], happened_at: '2018-06-19T00:00:00+08:00', user: user
      create :item, amount: 200, kind: 'income', tag_ids: [tag.id], happened_at: '2018-06-19T00:00:00+08:00', user: user
      do_request
      expect(status).to eq 200
      json = JSON.parse response_body
      expect(json['income']).to eq 500
      expect(json['expense']).to eq 400
      expect(json['balance']).to eq 100
    end
  end
end