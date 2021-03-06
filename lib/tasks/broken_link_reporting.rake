desc "Generates and emails CSV reports of all public documents containing broken links."
task :generate_broken_link_reports, [:reports_dir, :email_address, :organisation_slug] => [:environment] do |_, args|
  begin
    reports_dir       = args[:reports_dir]
    email_address     = args[:email_address]
    organisation_slug = args[:organisation_slug]
    report_zip_name   = "broken-link-reports-#{Date.today.strftime}.zip"
    report_zip_path   = Pathname.new(reports_dir).join(report_zip_name)
    logger            = Logger.new(Rails.root.join('log/broken_link_reporting.log'))

    logger.info("Cleaning up any existing reports.")
    FileUtils.mkpath reports_dir
    FileUtils.rm Dir.glob(reports_dir + '/*_links_report.csv')
    FileUtils.rm(report_zip_path) if File.exists?(report_zip_path)

    logger.info("Generating broken link reports...")
    organisation = Organisation.where(slug: organisation_slug).first if organisation_slug
    LinkReporterCsvService.new(reports_dir: reports_dir, organisation: organisation).generate

    logger.info("Reports generated. Zipping...")
    system "zip #{report_zip_path} #{reports_dir}/*_links_report.csv --junk-paths"

    logger.info("Reports zipped. Emailing to #{email_address}")
    Notifications.broken_link_reports(report_zip_path, email_address).deliver_now
    logger.info("Email sent.")
  rescue => e
    GovukError.notify(e, extra: { error_message: "Exception raised during broken link report generation: '#{e.message}'" })
    raise
  end
end
