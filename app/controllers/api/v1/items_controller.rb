class Api::V1::ItemsController < ApplicationController
  def index
    current_user_id = request.env['current_user_id']
    return head :unauthorized if current_user_id.nil?
    items = Item.where(user_id: current_user_id)
      .where(
        happened_at: (datetime_with_zone(params[:happened_after])..datetime_with_zone(params[:happened_before]))
      )    
    items = items.where(kind: params[:kind]) unless params[:kind].blank?
    items = items.page(params[:page])
    render json: { resources: items, pager: {
      page: params[:page] || 1,
      per_page: Item.default_per_page,
      count: items.count
    }}, methods: :tags
  end
  def create
    current_user = User.find request.env['current_user_id']
    return render status: :not_found  if current_user.nil?  
    item = Item.new params.permit(:amount, :happened_at, :kind, tag_ids: [] )   
    item.user_id = request.env['current_user_id']
    if item.save
      render json: {resource: item}
    else
      render json: {errors: item.errors}, status: :unprocessable_entity
    end
  end
  def balance
    current_user_id = request.env["current_user_id"]
    return head :unauthorized if current_user_id.nil?
    items = Item.where({user_id: current_user_id })
      .where({happened_at: params[:happened_after]..params[:happened_before] })
    income_items = []
    expense_items = []
    items.each{ |item|
      if item.kind === 'income'
        income_items << item
      else 
        expense_items << item
      end
    }
    income = income_items.sum(&:amount)
    expense = expense_items.sum(&:amount)
    render json: {income: income, expense: expense, balance: income - expense}
  end
  def summary
    hash = Hash.new
    items = Item
      .where(user_id: request.env['current_user_id'])
      .where(kind: params[:kind])
      .where(happened_at: params[:happened_after]..params[:happened_before])
    tags = []
      items.each do |item|
        tags += item.tags
      if params[:group_by] == 'happened_at'
        key = item.happened_at.in_time_zone('Beijing').strftime('%F')
        hash[key] ||= 0
        hash[key] += item.amount
      else
        item.tag_ids.each do |tag_id|
          key = tag_id
          hash[key] ||= 0
          hash[key] += item.amount
        end
      end
    end
    groups = hash
    .map { |key, value| {
      "#{params[:group_by]}": key, 
      tag: tags.find { |tag| tag.id == key},
      amount: value
      }
    }
    if params[:group_by] == 'happened_at'
      groups.sort! { |a, b| a[:happened_at] <=> b[:happened_at] }
    elsif params[:group_by] == 'tag_id'
      groups.sort! { |a, b| b[:amount] <=> a[:amount] }
    end
    render json: {
      groups: groups,
      total: items.sum(:amount)
    }
  end
end