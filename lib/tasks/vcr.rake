namespace :vcr do
  desc "Limpa cassetes VCR com mais de X dias"
  task clean_old: :environment do
    cassette_dir = Rails.root.join("spec/fixtures/vcr_cassettes")
    older_than = Time.now - 30.days # Ajuste conforme necessário

    puts "Procurando cassetes VCR mais antigas que #{older_than.strftime('%d/%m/%Y')}"

    if Dir.exist?(cassette_dir)
      count = 0
      Dir.glob("#{cassette_dir}/**/*.yml").each do |file|
        if File.mtime(file) < older_than
          puts "Removendo cassete antiga: #{file}"
          File.delete(file)
          count += 1
        end
      end
      puts "Total de cassetes removidas: #{count}"
    else
      puts "Diretório de cassetes não encontrado: #{cassette_dir}"
    end
  end

  desc "Limpa todas as cassetes VCR e regenera"
  task regenerate: :environment do
    cassette_dir = Rails.root.join("spec/fixtures/vcr_cassettes")

    if Dir.exist?(cassette_dir)
      puts "Removendo todas as cassetes VCR..."
      FileUtils.rm_rf(cassette_dir)
      FileUtils.mkdir_p(cassette_dir)
      puts "Diretório de cassetes limpo. Execute seus testes para regenerar."
    else
      puts "Diretório de cassetes não encontrado: #{cassette_dir}"
    end
  end
end
