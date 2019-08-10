class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy, :categories]
  before_filter :authorize
  helper_method :sort_column, :sort_direction
  after_action :handle_tags, only: [:update, :create]
  before_filter :authorize_admin, only: [:destroy]

  # GET /books
  # GET /books.json
  def index
    respond_to do |format| 
      format.html {
        if sort_column == "created_at"  
          @books = Book.all.order(created_at: :desc)
        else 
          @books = Book.lower_order(sort_column, sort_direction)
        end

        if params[:search].present?
          @books = Book.search(params[:search]).order(:author)
        end

        if params[:filter].present?
          @books = @books.joins(:book_categories).where('book_categories.category_id' => params[:filter])
        end

        @books = @books.paginate(page: params[:page])
      }
      format.json { @books = Book.all }
      format.csv { send_data Book.as_csv, filename: "books-#{Date.today}.csv" }
    end
  end

  def categories
    render json: @book.categories, status: 200
  end

  # GET /books/1
  # GET /books/1.json
  def show
  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # GET /books/1/edit
  def edit
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    end

    def sort_column
      Book.column_names.include?(params[:sort]) ? params[:sort] : "created_at"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:name, :isbn, :name_eng, :author, :language, :description_sindhi, :description_eng, :year, :publisher, :attachment, categories_attributes: [:id, :name, :_destroy])
    end

    def handle_tags
      tags = params[:tags] || []

      # Add new ones
      tags.each do |tag|
        tag_name = tag.capitalize
        category = Category.find_or_create_by name: tag_name
        BookCategory.find_or_create_by category: category, book: @book   
      end

      # Remove those that user chose not to keep
      @book.categories.reject{|c| tags.include? c.name.capitalize }.each do |category|
        BookCategory.find_by(category: category, book: @book).destroy
      end     
    end
end
