class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  helper_method :sort_column, :sort_direction
  before_action :authorize_admin, if: :admin_only_action?

  
  # GET /books
  # GET /books.json
  def index
    respond_to do |format| 
      format.html {
        @q = Book.ransack(params[:q])
        @q.sorts = 'created_at desc' if @q.sorts.empty?
        @books = @q.result(distinct: true).includes(:categories).with_attached_cover.with_attached_attachment.page(params[:page])
      }
      format.json { @books = Book.all }
      format.csv { send_data Book.as_csv, filename: "books-#{Date.today}.csv" }
    end
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
        # Create cover in background task if book was successfully created
        CreateCoversJob.perform_later @book

        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        keep_new_attachment
        @book.extract_fields_from_metadata

        flash.now[:success] = "Note: some fields were filled automatically from the book you provided. Recheck them and submit again."
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    @book.assign_attributes(book_params)
    new_file = @book.attachment_changes.key?('attachment')

    respond_to do |format|
      if @book.save
        # A new file needs a new cover.
        CreateCoversJob.perform_later @book if new_file

        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        keep_new_attachment
        format.html { render :edit, status: :unprocessable_entity }
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

    # Deleting books and the CSV export are admin-only, and both are checked
    # here. They cannot be two `before_action :authorize_admin` lines: Rails
    # keeps only the last one declared for a method, so the earlier one is
    # dropped and its action left unguarded.
    def admin_only_action?
      action_name == 'destroy' || (action_name == 'index' && request.format.csv?)
    end

    def sort_column
      Book.column_names.include?(params[:sort]) ? params[:sort] : "created_at"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:name, :isbn, :name_eng, :author, :translator, :translator_sindhi, :author_sindhi, :language, :description_sindhi, :description_eng, :year, :publisher, :attachment, tag_names: [])
    end

    # A failed save uploads nothing. Upload the new file anyway, so the form can
    # send it back as a signed id and the user does not have to choose it again.
    # A blob never attached is purged after a day (config/recurring.yml).
    def keep_new_attachment
      change = @book.attachment_changes['attachment']
      return if change.nil? || change.blob.persisted?

      change.upload
      change.blob.save!
    end
end
