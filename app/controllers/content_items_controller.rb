# frozen_string_literal: true

class ContentItemsController < SecureController
  def index
    @content_items = current_user.content_items
    @publishing_targets = PublishingTarget.where(content_item_id: @content_items.pluck(:id))
    @initial_targets = @publishing_targets
  end

  def show
    @content_item = ContentItem.find(params[:id])
    @publishing_targets = PublishingTarget.where(content_item_id: @content_item)
  end

  def search
    content_items = ContentItem.joins(:action_text_rich_text).where("lower(action_text_rich_texts.body) LIKE ? or lower(title) LIKE ?", "%#{params[:q].downcase}%", "%#{params[:q].downcase}%")
    @publishing_targets = PublishingTarget.where(content_item_id: content_items.uniq.pluck(:id)).order(publish_date: :desc)
    @initial_targets = @publishing_targets
    start_date = @publishing_targets.empty? ? Time.now.strftime("%Y-%m-%d") : @publishing_targets.last.publish_date.strftime("%Y-%m-%d")
  end

  def filter
    @social_network = SocialNetwork.find_by_description(params[:social_network_desciption])
    @publishing_targets = PublishingTarget.where("id IN (?) AND social_network_id = ?", params[:target_ids].split(","), @social_network.id)
    @initial_targets = PublishingTarget.where("id IN (?)", params[:target_ids].split(","))
    params[:start_date] =  params[:start_date].empty? ? Time.now.strftime("%Y-%m-%d") : params[:start_date]
  end

  def new
    @content_item = ContentItem.new
    @content_item.user = current_user
  end

  def create
    @content_item = ContentItem.new(content_item_params)
    @content_item.user = current_user

    if @content_item.save
      redirect_to content_items_path, notice: "#{@content_item.title} added"
    else
      render :new
    end
  end

  def edit
    @content_item = ContentItem.find(params[:id])
  end

  def update
    @content_item = ContentItem.find(params[:id])
    @content_item.assign_attributes(content_item_params)

    if @content_item.save
      redirect_to content_items_path, notice: "#{@content_item.title} updated"
    else
      render :edit
    end
  end

  def destroy
    @content_item = current_user.content_items.find(params[:id])
    @content_item.destroy

    redirect_to content_items_path, notice: "#{@content_item.title} deleted"
  end

  private

  def content_item_params
    params.require(:content_item).permit(:title, :body, social_network_ids: [])
  end
end
