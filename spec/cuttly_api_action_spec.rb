describe Fastlane::Actions::CuttlyApiAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The cuttly_api plugin is working!")

      Fastlane::Actions::CuttlyApiAction.run(nil)
    end
  end
end
