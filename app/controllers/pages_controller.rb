class PagesController < ApplicationController
  # Static informational pages (about, privacy, contact). Content lives in the
  # views; these actions exist only to render them.
  def about;   end
  def privacy; end
  def contact; end
end
