class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy, :categories]
  before_action :authorize
  helper_method :sort_column, :sort_direction
  after_action :handle_tags, only: [:update, :create]
  before_action :authorize_admin, only: [:destroy]
  before_action :authorize_admin, only: [:index], if: :format_csv?

  
  # GET /books
  # GET /books.json
  def index
    respond_to do |format| 
      format.html {
        @q = Book.ransack(params[:q])
        @q.sorts = 'created_at desc' if @q.sorts.empty?
        @books = @q.result(distinct: true).includes(:categories).page(params[:page])
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
    @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {autolink: true})
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
    filename = session[:attachment_path]
    if filename
      if File.file? filename
        @book.attachment = File.open(session[:attachment_path], 'r')
        @book.attachment.instance_write(:file_name, session[:attachment_name])
      end
      session.delete(:attachment_path)
      session.delete(:attachment_name)
    end

    respond_to do |format|
      if @book.save

        # Create cover in background task if book was successfully created
        CreateCoversJob.perform_later @book

        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        @book.extract_fields_from_metadata

        temp_file = Tempfile.new(["pdf", ".pdf"], binmode: true)
        temp_file.write Paperclip.io_adapters.for(@book.attachment).read
        temp_file.close

        session[:attachment_name] = @book.attachment.original_filename
        session[:attachment_path] = temp_file.path

        flash.now[:success] = "Note: some fields were filled automatically from the book you provided. Recheck them and submit again."
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    # If file changed, re-run cover art extractor
    old_file_name = @book.attachment_file_name

    respond_to do |format|
      
      if @book.update(book_params)
        
        if old_file_name != @book.attachment_file_name
          CreateCoversJob.perform_later @book
        end
        
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

    def format_csv?
      request.format.csv?
    end

    def sort_column
      Book.column_names.include?(params[:sort]) ? params[:sort] : "created_at"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:name, :isbn, :name_eng, :author, :translator, :translator_sindhi, :author_sindhi, :language, :description_sindhi, :description_eng, :year, :publisher, :attachment, categories_attributes: [:id, :name, :_destroy])
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
