class CategoriesController < ApplicationController
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  before_filter :authorize

  # GET /categories
  # GET /categories.json
  def index
    @categories = Category.all
  end

  # GET /categories/1
  # GET /categories/1.json
  def show
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # GET /categories/1/edit
  def edit
  end

  # POST /categories
  # POST /categories.json
  def create
    @category = Category.new(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to @category, notice: 'Category was successfully created.' }
        format.json { render :show, status: :created, location: @category }
      else
        format.html { render :new }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categories/1
  # PATCH/PUT /categories/1.json
  def update
    respond_to do |format|
      if @category.update(category_params)
        format.html { redirect_to @category, notice: 'Category was successfully updated.' }
        format.json { render :show, status: :ok, location: @category }
      else
        format.html { render :edit }
        format.json { render json: @category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.json
  def destroy
    @category.destroy
    respond_to do |format|
      format.html { redirect_to categories_url, notice: 'Category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_category
      @category = Category.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def category_params
      params.require(:category).permit(:name)
    end

    def filter_css
      '.filter {
  .filter-nav {
    margin: 1rem 0;
  }

  .filter-body {
    display: flex;
    flex-wrap: wrap;
  }

  .filter-tag {
    &#tag-all:checked ~ .filter-nav .chip[for="tag-all"],
    &#tag-science:checked ~ .filter-nav .chip[for="tag-science"],
    &#tag-roleplaying:checked ~ .filter-nav .chip[for="tag-roleplaying"],
    &#tag-shooter:checked ~ .filter-nav .chip[for="tag-shooter"],
    &#tag-sports:checked ~ .filter-nav .chip[for="tag-sports"] {
      background: @primary-color;
      color: @light-color;
    }

    &#tag-science:checked ~ .filter-body .column:not([data-tag~="tag-science"]),
    &#tag-roleplaying:checked ~ .filter-body .column:not([data-tag~="tag-roleplaying"]),
    &#tag-shooter:checked ~ .filter-body .column:not([data-tag~="tag-shooter"]),
    &#tag-sports:checked ~ .filter-body .column:not([data-tag~="tag-sports"]) {
      display: none;
    }
  }
}'
    end
end
