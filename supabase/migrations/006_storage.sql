-- 006_storage.sql
-- Create buckets
INSERT INTO storage.buckets (id, name, public) VALUES
('avatars', 'avatars', true),
('campaign-images', 'campaign-images', true),
('product-images', 'product-images', true),
('product-files', 'product-files', false),
('kyc-documents', 'kyc-documents', false),
('deliverables', 'deliverables', false),
('service-files', 'service-files', false),
('support-files', 'support-files', false)
ON CONFLICT (id) DO NOTHING;

-- Avatars policies
CREATE POLICY "Avatars are publicly accessible" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload their own avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);

-- KYC policies (Private)
CREATE POLICY "Users can view own KYC" ON storage.objects FOR SELECT USING (bucket_id = 'kyc-documents' AND auth.uid() = owner);
CREATE POLICY "Users can upload KYC" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid() = owner);
CREATE POLICY "Admins can view all KYC" ON storage.objects FOR SELECT USING (bucket_id = 'kyc-documents' AND (SELECT is_admin(auth.uid())));

-- Product Files (Private, Download logic handled via signed URLs)
CREATE POLICY "Admins and owners manage product files" ON storage.objects FOR ALL USING (bucket_id = 'product-files' AND (auth.uid() = owner OR (SELECT is_admin(auth.uid()))));
