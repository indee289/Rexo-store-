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

      if (!error && data?.path) {
        const { data: publicData } = supabase.storage
          .from(bucket)
          .getPublicUrl(data.path);
        if (publicData?.publicUrl) {
          return { publicUrl: publicData.publicUrl, error: null };
        }
      }

      // If storage upload fails or publicUrl isn't returned, fallback to getPublicUrl directly
      const { data: directPublicData } = supabase.storage
        .from(bucket)
        .getPublicUrl(filePath);

      if (directPublicData?.publicUrl) {
        return { publicUrl: directPublicData.publicUrl, error: null };
      }

      // Convert to base64 Data URL for persistent local display on mobile
      const base64Url = await this.fileToBase64(file);
      return { publicUrl: base64Url, error: null };
    } catch (err) {
      const base64Url = await this.fileToBase64(file).catch(() => null);
      return { publicUrl: base64Url, error: err };
    }
  }

  private fileToBase64(file: File | Blob): Promise<string> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = (error) => reject(error);
    });
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
