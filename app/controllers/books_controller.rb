class BooksController < ApplicationController
  # Where a failed create keeps the uploaded file until the user resubmits.
  # Deliberately not Tempfile: Tempfile deletes the file when the object is
  # garbage collected, which happens long before the form comes back.
  PENDING_UPLOAD_DIR = Rails.root.join("tmp", "pending_uploads")
  PENDING_UPLOAD_TTL = 1.day

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

    stashed_path = session.delete(:attachment_path)
    stashed_name = session.delete(:attachment_name)

    if stashed_path && !pending_upload?(stashed_path)
      # The stashed upload is gone. Saving now would create a book with no file
      # and still report success, which is how books 192 and 213 ended up empty.
      flash.now[:error] = "The file you uploaded is no longer available. Please choose it again and resubmit."

      respond_to do |format|
        format.html { render :new }
        format.json { render json: { attachment: ["must be uploaded again"] }, status: :unprocessable_entity }
      end
      return
    end

    if stashed_path
      @book.attachment = File.open(stashed_path, 'rb')
      @book.attachment.instance_write(:file_name, stashed_name)
    end

    respond_to do |format|
      if @book.save
        File.delete(stashed_path) if stashed_path && File.file?(stashed_path)

        # Create cover in background task if book was successfully created
        CreateCoversJob.perform_later @book

        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        @book.extract_fields_from_metadata

        if @book.attachment.present?
          session[:attachment_name] = @book.attachment.original_filename
          session[:attachment_path] = stash_upload(@book.attachment)
        end

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

    # True only for a file this controller stashed and that is still there.
    def pending_upload?(path)
      File.file?(path) && File.dirname(File.expand_path(path)) == PENDING_UPLOAD_DIR.to_s
    end

    # Writes the upload somewhere it will survive until the user resubmits, and
    # returns the path. Old stashes are swept on the way past.
    def stash_upload(attachment)
      FileUtils.mkdir_p PENDING_UPLOAD_DIR
      sweep_pending_uploads

      path = PENDING_UPLOAD_DIR.join("#{SecureRandom.uuid}#{File.extname(attachment.original_filename)}")
      File.binwrite path, Paperclip.io_adapters.for(attachment).read
      path.to_s
    end

    def sweep_pending_uploads
      Dir.glob(PENDING_UPLOAD_DIR.join("*")).each do |file|
        File.delete(file) if File.mtime(file) < PENDING_UPLOAD_TTL.ago
      rescue Errno::ENOENT
        # Swept by another request in the meantime.
      end
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
