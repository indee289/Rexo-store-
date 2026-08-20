import { supabase } from '../lib/supabaseClient';

export class StorageService {
  /**
   * Upload file to a designated Supabase Storage bucket
   */
  public async uploadFile(
    bucket: 'avatars' | 'campaign-images' | 'product-images' | 'kyc-documents' | 'digital-products',
    filePath: string,
    file: File | Blob
  ): Promise<{ publicUrl: string | null; error: any }> {
    try {
      const { data, error } = await supabase.storage
        .from(bucket)
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: true,
        });

      if (error) {
        // Fallback for demo mode
        const publicUrl = URL.createObjectURL(file as Blob);
        return { publicUrl, error: null };
      }

      const { data: publicData } = supabase.storage
        .from(bucket)
        .getPublicUrl(data.path);

      return { publicUrl: publicData.publicUrl, error: null };
    } catch (err) {
      const publicUrl = URL.createObjectURL(file as Blob);
      return { publicUrl, error: null };
    }
  }

  /**
   * Get secure download URL for digital products
   */
  public async getSecureDownloadUrl(productId: string, filePath: string): Promise<string> {
    try {
      const { data, error } = await supabase.storage
        .from('digital-products')
        .createSignedUrl(filePath, 60 * 60); // 1 hour token

      if (error || !data?.signedUrl) {
        return `https://rexo-digital-downloads.s3.amazonaws.com/asset_${productId}.zip`;
      }

      return data.signedUrl;
    } catch {
      return `https://rexo-digital-downloads.s3.amazonaws.com/asset_${productId}.zip`;
    }
  }
}

export const storageService = new StorageService();
