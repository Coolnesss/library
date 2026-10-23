class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  before_action :authorize_admin, if: :admin_only_action?

  
  # GET /books
  # GET /books.json
  def index
    respond_to do |format| 
      format.html {
        @search = BookSearch.new(params.permit(*BookSearch::PARAMS))
        results = @search.results
        @books = results.includes(:categories).with_attached_cover.with_attached_attachment.page(params[:page])
        # Run the search's filters once, then count over the ids.
        @stats = Book.where(id: results.unscope(:order).select(:id).map(&:id)).stats
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
        # The browser normally sends the cover and page count; otherwise
        # (Word files, no JavaScript) the job makes what is missing.
        CreateCoversJob.perform_later @book unless @book.cover.attached? && @book.pages

        format.html { redirect_to @book, notice: t('books.created') }
        format.json { render :show, status: :created, location: @book }
      else
        keep_new_attachment
        format.html { flash.now[:error] = t('form_errors'); render :new, status: :unprocessable_entity }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    @book.assign_attributes(book_params)
    new_file = @book.attachment_changes.key?('attachment')
    if new_file
      # The old file's cover and page count no longer apply; the browser sends
      # new ones, or the job makes them.
      @book.cover = nil unless @book.attachment_changes.key?('cover')
      @book.pages = nil unless book_params[:pages].present?
    end

    respond_to do |format|
      if @book.save
        CreateCoversJob.perform_later @book if new_file && !(@book.cover.attached? && @book.pages)

        format.html { redirect_to @book, notice: t('books.updated') }
        format.json { render :show, status: :ok, location: @book }
      else
        keep_new_attachment
        format.html { flash.now[:error] = t('form_errors'); render :edit, status: :unprocessable_entity }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: t('books.destroyed') }
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:name, :isbn, :name_eng, :author, :translator, :translator_sindhi, :author_sindhi, :language, :description_sindhi, :description_eng, :year, :publisher, :attachment, :cover, :pages, tag_names: [])
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
